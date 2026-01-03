#!/usr/bin/env bashio
# shellcheck shell=bash
set -euo pipefail
# hadolint ignore=SC2155

#################
# Define config #
#################

CONFIGSOURCE="/config/addons_config/zoneminder"
mkdir -p "$CONFIGSOURCE"

if [ ! -f "$CONFIGSOURCE/zm.conf" ]; then
    # Copy conf file on first run
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

        # Use values from MariaDB service
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

        is_likely_zoneminder_db() {
            # Returns 0 if DB looks like ZoneMinder, 1 otherwise
            local db="$1"

            # Strict requirement: these two tables are very characteristic for ZM
            local required_count
            required_count="$("${mysql_base[@]}" -e \
                "SELECT COUNT(*) FROM information_schema.tables
                 WHERE table_schema='${db}'
                   AND LOWER(table_name) IN ('config','monitors');" \
                2>/dev/null || echo 0)"

            # Firefly III-ish signature tables (heuristic)
            local firefly_count
            firefly_count="$("${mysql_base[@]}" -e \
                "SELECT COUNT(*) FROM information_schema.tables
                 WHERE table_schema='${db}'
                   AND LOWER(table_name) IN (
                     'accounts','transactions','transaction_journals','categories',
                     'budgets','bills','tags','piggy_banks','rules','rule_groups'
                   );" \
                2>/dev/null || echo 0)"

            # Must have BOTH required ZM tables and none of the Firefly signature tables
            [ "${required_count:-0}" -ge 2 ] && [ "${firefly_count:-0}" -eq 0 ]
        }

        bashio::log.info "Creating database for ZoneMinder if required"
        "${mysql_base[@]}" -e "CREATE DATABASE IF NOT EXISTS \`${ZM_DB_NAME}\`;"

        # --- Legacy fix: previous buggy addon used DB name 'firefly' ---
        LEGACY_DB_NAME="firefly"

        legacy_db="$("${mysql_base[@]}" -e "SHOW DATABASES LIKE '${LEGACY_DB_NAME}';" || true)"
        if [ -n "$legacy_db" ]; then
            # First: verify legacy DB looks like ZoneMinder, not an actual Firefly DB
            if ! is_likely_zoneminder_db "$LEGACY_DB_NAME"; then
                bashio::log.warning "Legacy database '${LEGACY_DB_NAME}' exists but does NOT look like ZoneMinder. Skipping migration to avoid touching a real Firefly database."
            else
                # Second: migrate only if target appears empty and legacy has data
                target_tables="$("${mysql_base[@]}" -e \
                    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${ZM_DB_NAME}';" \
                    2>/dev/null || echo 0)"
                legacy_tables="$("${mysql_base[@]}" -e \
                    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${LEGACY_DB_NAME}';" \
                    2>/dev/null || echo 0)"

                if [ "${target_tables:-0}" -eq 0 ] && [ "${legacy_tables:-0}" -gt 0 ]; then
                    bashio::log.warning "Detected legacy ZoneMinder DB named '${LEGACY_DB_NAME}'. Migrating to '${ZM_DB_NAME}'..."

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
                else
                    bashio::log.info "Legacy DB '${LEGACY_DB_NAME}' found but migration skipped (target not empty or legacy empty)."
                fi
            fi
        fi
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
/./usr/local/bin/entrypoint.sh
