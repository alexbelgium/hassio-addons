#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail
# hadolint ignore=SC2155

#################
# Define config #
#################

CONFIGSOURCE="/config/addons_config/zoneminder"
mkdir -p "$CONFIGSOURCE"

if [ ! -f "$CONFIGSOURCE/zm.conf" ]; then
    cp -f /etc/zm/zm.conf "$CONFIGSOURCE/zm.conf"
fi

###################
# Define database #
###################

bashio::log.info "Defining database"

case "$(bashio::config "DB_CONNECTION")" in
    mariadb_addon)
        bashio::log.info "Using MariaDB addon. Detecting values..."

        if ! bashio::services.available 'mysql'; then
            bashio::log.fatal "Local database access should be provided by the MariaDB addon"
            bashio::exit.nok "Please ensure it is installed and started"
        fi

        DB_CONNECTION="mysql"
        remoteDB="1"
        ZM_DB_HOST="$(bashio::services "mysql" "host")"
        ZM_DB_PORT="$(bashio::services "mysql" "port")"
        ZM_DB_NAME="zm"
        ZM_DB_USER="$(bashio::services "mysql" "username")"
        ZM_DB_PASS="$(bashio::services "mysql" "password")"
        export DB_CONNECTION remoteDB ZM_DB_HOST ZM_DB_PORT ZM_DB_NAME ZM_DB_USER ZM_DB_PASS

        # DO NOT log passwords
        bashio::log.blue "ZM_DB_HOST=${ZM_DB_HOST}"
        bashio::log.blue "ZM_DB_PORT=${ZM_DB_PORT}"
        bashio::log.blue "ZM_DB_NAME=${ZM_DB_NAME}"
        bashio::log.blue "ZM_DB_USER=${ZM_DB_USER}"

        bashio::log.warning "ZoneMinder is using the MariaDB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"

        # Common mysql invocation (batch + no headers)
        mysql_base=(
            mysql
            -u "${ZM_DB_USER}"
            -p"${ZM_DB_PASS}"
            -h "${ZM_DB_HOST}"
            -P "${ZM_DB_PORT}"
            --batch
            --skip-column-names
        )

        db_exists() {
            local db="$1"
            local out
            out="$("${mysql_base[@]}" -e \
                "SELECT schema_name FROM information_schema.schemata WHERE schema_name='${db}';" \
                2>/dev/null || true)"
            [ -n "$out" ]
        }

        table_count() {
            local db="$1"
            # If schema doesn't exist, count should be 0
            "${mysql_base[@]}" -e \
                "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${db}';" \
                2>/dev/null || echo 0
        }

        is_likely_zoneminder_db() {
            # Returns 0 if DB looks like ZoneMinder, 1 otherwise
            local db="$1"

            if ! db_exists "$db"; then
                return 1
            fi

            # Strong ZoneMinder signature: Config + Monitors (required)
            local zm_required
            zm_required="$("${mysql_base[@]}" -e \
                "SELECT COUNT(*) FROM information_schema.tables
                 WHERE table_schema='${db}'
                   AND LOWER(table_name) IN ('config','monitors');" \
                2>/dev/null || echo 0)"

            # Firefly-ish signature tables (heuristic blacklist)
            local ff_sig
            ff_sig="$("${mysql_base[@]}" -e \
                "SELECT COUNT(*) FROM information_schema.tables
                 WHERE table_schema='${db}'
                   AND LOWER(table_name) IN (
                     'accounts','transactions','transaction_journals','categories',
                     'budgets','bills','tags','piggy_banks','rules','rule_groups'
                   );" \
                2>/dev/null || echo 0)"

            [ "${zm_required:-0}" -ge 2 ] && [ "${ff_sig:-0}" -eq 0 ]
        }

        create_db_if_missing() {
            local db="$1"
            "${mysql_base[@]}" -e "CREATE DATABASE IF NOT EXISTS \`${db}\`;" >/dev/null
        }

        # --- Legacy fix: previous buggy addon used DB name 'firefly' ---
        LEGACY_DB_NAME="firefly"
        need_migration="0"

        if db_exists "$LEGACY_DB_NAME"; then
            if is_likely_zoneminder_db "$LEGACY_DB_NAME"; then
                legacy_tables="$(table_count "$LEGACY_DB_NAME")"
                target_tables="0"
                if db_exists "$ZM_DB_NAME"; then
                    target_tables="$(table_count "$ZM_DB_NAME")"
                fi

                # Only migrate if:
                # - legacy has data
                # - target has 0 tables (either missing or empty)
                if [ "${legacy_tables:-0}" -gt 0 ] && [ "${target_tables:-0}" -eq 0 ]; then
                    need_migration="1"
                else
                    bashio::log.info "Legacy DB '${LEGACY_DB_NAME}' detected but migration skipped (target not empty or legacy empty)."
                fi
            else
                bashio::log.warning "Database '${LEGACY_DB_NAME}' exists but does NOT look like ZoneMinder. Skipping migration to avoid touching a real Firefly database."
            fi
        fi

        # IMPORTANT: do NOT pre-create target DB before deciding on migration.
        # Create target only when needed (migration) and finally ensure it exists for normal start.

        if [ "$need_migration" = "1" ]; then
            bashio::log.warning "Detected legacy ZoneMinder DB named '${LEGACY_DB_NAME}'. Migrating to '${ZM_DB_NAME}'..."

            create_db_if_missing "$ZM_DB_NAME"

            dump_bin=""
            if command -v mysqldump >/dev/null 2>&1; then
                dump_bin="mysqldump"
            elif command -v mariadb-dump >/dev/null 2>&1; then
                dump_bin="mariadb-dump"
            fi

            if [ -z "$dump_bin" ]; then
                bashio::log.warning "mysqldump/mariadb-dump not available; please migrate manually."
            else
                if "$dump_bin" \
                    -u "${ZM_DB_USER}" -p"${ZM_DB_PASS}" \
                    -h "${ZM_DB_HOST}" -P "${ZM_DB_PORT}" \
                    --routines --events --triggers \
                    "${LEGACY_DB_NAME}" | \
                    mysql \
                        -u "${ZM_DB_USER}" -p"${ZM_DB_PASS}" \
                        -h "${ZM_DB_HOST}" -P "${ZM_DB_PORT}" \
                        "${ZM_DB_NAME}"; then
                    bashio::log.info "Legacy database migration completed."
                    bashio::log.warning "Optional: you may now drop '${LEGACY_DB_NAME}' manually if desired."
                else
                    bashio::log.warning "Legacy database migration failed; please migrate manually."
                fi
            fi
        fi

        # Ensure target DB exists for ZoneMinder startup (after migration decision)
        bashio::log.info "Ensuring ZoneMinder database '${ZM_DB_NAME}' exists"
        create_db_if_missing "$ZM_DB_NAME"
        ;;

    external)
        bashio::log.info "Using remote database. Requirement: filling all addon options fields, and making sure the database already exists"

        for key in "ZM_DB_HOST" "ZM_DB_PORT" "ZM_DB_NAME" "ZM_DB_USER" "ZM_DB_PASS"; do
            if ! bashio::config.has_value "$key"; then
                bashio::exit.nok "Remote database has been specified but $key is not defined in addon options"
            fi
        done

        DB_CONNECTION="mysql"
        remoteDB="1"
        ZM_DB_HOST="$(bashio::config "ZM_DB_HOST")"
        ZM_DB_PORT="$(bashio::config "ZM_DB_PORT")"
        ZM_DB_NAME="$(bashio::config "ZM_DB_NAME")"
        ZM_DB_USER="$(bashio::config "ZM_DB_USER")"
        ZM_DB_PASS="$(bashio::config "ZM_DB_PASS")"
        export DB_CONNECTION remoteDB ZM_DB_HOST ZM_DB_PORT ZM_DB_NAME ZM_DB_USER ZM_DB_PASS

        bashio::log.blue "ZM_DB_HOST=${ZM_DB_HOST}"
        bashio::log.blue "ZM_DB_PORT=${ZM_DB_PORT}"
        bashio::log.blue "ZM_DB_NAME=${ZM_DB_NAME}"
        bashio::log.blue "ZM_DB_USER=${ZM_DB_USER}"
        # DO NOT log passwords
        ;;

    *)
        bashio::log.info "Using internal database"
        ;;
esac

##############
# LAUNCH APP #
##############

bashio::log.info "Please wait while the app is loading !"
exec /usr/local/bin/entrypoint.sh
