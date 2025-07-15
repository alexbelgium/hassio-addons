#!/usr/bin/env bashio
# shellcheck shell=bash
set -euo pipefail

CONFIG_HOME="/config"
PGDATA="${PGDATA:-/config/database}"
export PGDATA
PG_MAJOR_VERSION="${PG_MAJOR:-15}"
RESTART_FLAG_FILE="$CONFIG_HOME/restart_needed"

fix_permissions() {
	mkdir -p "$PGDATA"
	chown -R postgres:postgres "$PGDATA"
	chmod 700 "$PGDATA"
	if [ -d /config/backups ]; then
		chown -R postgres:postgres /config/backups
		chmod 700 /config/backups
	fi
}

chmod -R 755 "$CONFIG_HOME"
RESTART_NEEDED=false
cd /config || true

get_pgdata_version() {
	if [ -f "$PGDATA/PG_VERSION" ]; then
		cat "$PGDATA/PG_VERSION"
	else
		bashio::log.error "FATAL: $PGDATA/PG_VERSION not found; cannot determine cluster version."
		exit 1
	fi
}

extract_so_from_deb() {
	local debfile="$1" targetdir="$2" sofile="$3"
	local tmpdir
	tmpdir=$(mktemp -d)
	dpkg-deb -x "$debfile" "$tmpdir"
	find "$tmpdir" -name "$sofile" -exec cp {} "$targetdir" \;
	rm -rf "$tmpdir"
}

install_vchord_and_vectors_for_old_pg() {
	local old_pgver="$1"
	local vectorchord_tag="${VECTORCHORD_TAG:-0.3.0}"
	local pgvectors_tag="${PGVECTORS_TAG:-0.3.0}"
	case "$(uname -m)" in
	x86_64 | amd64 | AMD64 | x86-64) targetarch=amd64 ;;
	aarch64 | arm64 | ARM64) targetarch=arm64 ;;
	*)
		echo "Unsupported architecture: $(uname -m)"
		exit 1
		;;
	esac

	local old_pg_lib="/usr/lib/postgresql/$old_pgver/lib"
	mkdir -p "$old_pg_lib"

	# VectorChord
	local vchord_deb="/tmp/vchord-${old_pgver}.deb"
	local vchord_url="https://github.com/tensorchord/VectorChord/releases/download/${vectorchord_tag}/postgresql-${old_pgver}-vchord_${vectorchord_tag}-1_${targetarch}.deb"
	bashio::log.info "Downloading $vchord_url"
	wget -nv -O "$vchord_deb" "$vchord_url"
	extract_so_from_deb "$vchord_deb" "$old_pg_lib" "vchord.so"
	rm -f "$vchord_deb"

	# pgvecto.rs
	local vectors_deb="/tmp/pgvectors-${old_pgver}.deb"
	local vectors_url="https://github.com/tensorchord/pgvecto.rs/releases/download/v${pgvectors_tag}/vectors-pg${old_pgver}_${pgvectors_tag}_${targetarch}.deb"
	bashio::log.info "Downloading $vectors_url"
	wget -nv -O "$vectors_deb" "$vectors_url"
	extract_so_from_deb "$vectors_deb" "$old_pg_lib" "vectors.so"
	rm -f "$vectors_deb"
}

drop_vectors_everywhere() {
	local old_pgver="$1"
	fix_permissions

	su - postgres -c "$BINARIES_DIR/$old_pgver/bin/pg_ctl -w -D '$PGDATA' \
		-o \"-c config_file=/etc/postgresql/postgresql.conf \
		    -c listen_addresses='' -c port=65432\" start"

	for db in $(su - postgres -c \
		"$BINARIES_DIR/$old_pgver/bin/psql -U \"$DB_USERNAME\" -Atc \
		    \"SELECT datname FROM pg_database WHERE datistemplate = false AND datallowconn\""); do
		if su - postgres -c \
			"$BINARIES_DIR/$old_pgver/bin/psql -U \"$DB_USERNAME\" -d $db -Atc \
			    \"SELECT 1 FROM pg_extension WHERE extname='vectors'\"" | grep -q 1; then
			bashio::log.warning "Dropping extension vectors from DB $db"
			su - postgres -c \
				"$BINARIES_DIR/$old_pgver/bin/psql -U \"$DB_USERNAME\" -d $db -c \
				    'DROP EXTENSION vectors CASCADE;'"
		fi
	done

	su - postgres -c "$BINARIES_DIR/$old_pgver/bin/pg_ctl -w -D '$PGDATA' stop"
}

start_postgres() {
	bashio::log.info "Starting PostgreSQL..."
	if [ "$(bashio::info.arch)" = "armv7" ]; then
		bashio::log.warning "ARMv7 detected: Starting without vectors.so"
		/usr/local/bin/immich-docker-entrypoint.sh postgres &
	else
		/usr/local/bin/immich-docker-entrypoint.sh postgres -c config_file=/etc/postgresql/postgresql.conf &
	fi
	true
}

wait_for_postgres() {
	local tries=0
	while ! pg_isready -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; do
		tries=$((tries + 1))
		[ "$tries" -ge 60 ] && {
			bashio::log.error "Postgres did not start after 2 minutes, aborting."
			exit 1
		}
		echo "PostgreSQL is starting up... ($tries/60)"
		sleep 2
	done
}

restart_immich_addons_if_flagged() {
	[ ! -f "$RESTART_FLAG_FILE" ] && return 0
	bashio::log.warning "Detected pending Immich add‑on restart flag. Restarting all running Immich add‑ons…"

	local addons_json found=0
	addons_json=$(curl -fsSL -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/addons) || {
		bashio::log.error "Supervisor API call failed or unauthorized: $addons_json"
		rm -f "$RESTART_FLAG_FILE"
		return 1
	}

	if command -v jq >/dev/null; then
		for slug in $(echo "$addons_json" | jq -r '.addons[] | select(.state=="started") | .slug'); do
			if [[ "$slug" == *immich* ]]; then
				bashio::log.info "Restarting addon $slug"
				curl -fsSL -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" "http://supervisor/addons/$slug/restart"
				found=1
			fi
		done
	else
		for slug in $(echo "$addons_json" | grep -o '"slug":"[^"]*"' | cut -d: -f2 | tr -d '"'); do
			if [[ "$slug" == *immich* ]]; then
				bashio::log.info "Restarting addon $slug"
				curl -fsSL -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" "http://supervisor/addons/$slug/restart"
				found=1
			fi
		done
	fi

	[ "$found" -eq 0 ] && bashio::log.info "No Immich-related addon found running."
	rm -f "$RESTART_FLAG_FILE"
}

# ---------------------------  DB connection setup  ---------------------------
DB_PORT=5432
DB_HOSTNAME=localhost
DB_PASSWORD="$(bashio::config 'POSTGRES_PASSWORD')"
DB_PASSWORD="$(jq -rn --arg x "$DB_PASSWORD" '$x|@uri')"

if bashio::config.has_value "POSTGRES_USER"; then
	DB_USERNAME="$(bashio::config 'POSTGRES_USER')"
else
	DB_USERNAME="postgres"
fi
export DB_PORT DB_HOSTNAME DB_USERNAME DB_PASSWORD
# -----------------------------------------------------------------------------

get_available_extension_version() {
	local extname="$1"
	psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/postgres" -v ON_ERROR_STOP=1 -tAc \
		"SELECT default_version FROM pg_available_extensions WHERE name = '$extname';" 2>/dev/null | xargs
}

is_extension_available() {
	local extname="$1"
	local result
	result=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/postgres" -v ON_ERROR_STOP=1 -tAc \
		"SELECT 1 FROM pg_available_extensions WHERE name = '$extname';" 2>/dev/null | xargs)
	[[ "$result" == "1" ]]
}

get_user_databases() {
	psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/postgres" -v ON_ERROR_STOP=1 -tAc \
		"SELECT datname FROM pg_database WHERE datistemplate = false AND datallowconn = true;"
}

get_installed_extension_version() {
	local extname="$1" dbname="$2"
	psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/$dbname" -v ON_ERROR_STOP=1 -tAc \
		"SELECT extversion FROM pg_extension WHERE extname = '$extname';" 2>/dev/null | xargs
}

compare_versions() {
	local v1="$1" v2="$2"
	[ "$v1" = "$v2" ] && return 1
	[ "$(printf '%s\n' "$v1" "$v2" | sort -V | head -n1)" = "$v1" ]
}

show_db_extensions() {
	bashio::log.info "==== PostgreSQL databases and enabled extensions ===="
	for db in $(get_user_databases); do
		bashio::log.info "Database: $db"
		exts=$(psql "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOSTNAME:$DB_PORT/$db" -tAc \
			"SELECT extname || ' (v' || extversion || ')' FROM pg_extension ORDER BY extname;")
		if [ -n "$exts" ]; then
			while read -r ext; do
				[ -n "$ext" ] && bashio::log.info "    - $ext"
			done <<<"$exts"
		else
			bashio::log.info "    (no extensions enabled)"
		fi
	done
	bashio::log.info "=============================================="
}

upgrade_extension_if_needed() {
	local extname="$1"
	is_extension_available "$extname" || {
		bashio::log.info "$extname extension not available."
		return
	}

	local available_version
	available_version=$(get_available_extension_version "$extname")
	[ -z "$available_version" ] && {
		bashio::log.info "Could not determine available version for $extname."
		return
	}

	for db in $(get_user_databases); do
		local installed_version
		installed_version=$(get_installed_extension_version "$extname" "$db")
		[ -z "$installed_version" ] && continue

		if compare_versions "$installed_version" "$available_version"; then
			bashio::log.info "Upgrading $extname in $db from $installed_version to $available_version"
			if psql -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$DB_USERNAME" -d "$db" -v ON_ERROR_STOP=1 -c "ALTER EXTENSION $extname UPDATE;"; then
				bashio::log.info "Reindexing database $db"
				psql -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$DB_USERNAME" -d "$db" -v ON_ERROR_STOP=1 -c "REINDEX DATABASE $db;"
				RESTART_NEEDED=true
			else
				bashio::log.error "Failed to upgrade $extname in $db. Aborting startup."
				exit 1
			fi
		else
			bashio::log.info "$extname in $db already at latest version ($installed_version)"
		fi
	done
}

upgrade_postgres_if_needed() {
	CLUSTER_VERSION=$(get_pgdata_version)
	IMAGE_VERSION="$PG_MAJOR_VERSION"
	[ "$CLUSTER_VERSION" = "$IMAGE_VERSION" ] && {
		bashio::log.info "PostgreSQL data directory version ($CLUSTER_VERSION) matches image version ($IMAGE_VERSION)."
		return
	}

	bashio::log.warning "Postgres data directory version is $CLUSTER_VERSION but image wants $IMAGE_VERSION. Running upgrade..."
	export DATA_DIR="$PGDATA" BINARIES_DIR="/usr/lib/postgresql" BACKUP_DIR="/config/backups"
	export PSQL_VERSION="$IMAGE_VERSION" SUPPORTED_POSTGRES_VERSIONS="$CLUSTER_VERSION $IMAGE_VERSION"

	apt-get update &>/dev/null
	apt-get install -y procps rsync "postgresql-$IMAGE_VERSION" "postgresql-$CLUSTER_VERSION"

	[ -d "$BINARIES_DIR/$CLUSTER_VERSION/bin" ] || {
		bashio::log.error "Old postgres binaries missing."
		exit 1
	}
	[ -d "$BINARIES_DIR/$IMAGE_VERSION/bin" ] || {
		bashio::log.error "New postgres binaries missing."
		exit 1
	}

	install_vchord_and_vectors_for_old_pg "$CLUSTER_VERSION"

	mkdir -p "$BACKUP_DIR"
	local backup_target="$BACKUP_DIR/postgresql-$CLUSTER_VERSION"
	bashio::log.info "Backing up data directory to $backup_target..."
	rsync -a --delete "$PGDATA/" "$backup_target/" || {
		bashio::log.error "Backup with rsync failed!"
		exit 1
	}

	cp -n --preserve=mode "/var/postgresql-conf-tpl/postgresql.hdd.conf" /etc/postgresql/postgresql.conf
	sed -i "s@##PGDATA@$PGDATA@" /etc/postgresql/postgresql.conf

	drop_vectors_everywhere "$CLUSTER_VERSION"
	fix_permissions

	bashio::log.info "Starting old Postgres ($CLUSTER_VERSION) to capture encoding/locale settings"
	su - postgres -c "$BINARIES_DIR/$CLUSTER_VERSION/bin/pg_ctl -w -D '$PGDATA' -o \"-c config_file=/etc/postgresql/postgresql.conf\" start"

	LC_COLLATE=$(su - postgres -c "$BINARIES_DIR/$CLUSTER_VERSION/bin/psql -U \"$DB_USERNAME\" -d postgres -Atc 'SHOW LC_COLLATE;'")
	LC_CTYPE=$(su - postgres -c "$BINARIES_DIR/$CLUSTER_VERSION/bin/psql -U \"$DB_USERNAME\" -d postgres -Atc 'SHOW LC_CTYPE;'")
	ENCODING=$(su - postgres -c "$BINARIES_DIR/$CLUSTER_VERSION/bin/psql -U \"$DB_USERNAME\" -d postgres -Atc 'SHOW server_encoding;'")
	bashio::log.info "Detected cluster: LC_COLLATE=$LC_COLLATE, LC_CTYPE=$LC_CTYPE, ENCODING=$ENCODING"

	bashio::log.info "Stopping old Postgres ($CLUSTER_VERSION)"
	su - postgres -c "$BINARIES_DIR/$CLUSTER_VERSION/bin/pg_ctl -w -D '$PGDATA' -o \"-c config_file=/etc/postgresql/postgresql.conf\" stop"

	rm -rf "$PGDATA"
	fix_permissions

	bashio::log.info "Initializing new data cluster for $IMAGE_VERSION"
	su - postgres -c "$BINARIES_DIR/$IMAGE_VERSION/bin/initdb --encoding=$ENCODING --lc-collate=$LC_COLLATE --lc-ctype=$LC_CTYPE -D '$PGDATA'"
	fix_permissions

	bashio::log.info "Running pg_upgrade from $CLUSTER_VERSION → $IMAGE_VERSION"
	chmod 700 "$PGDATA" "$backup_target"
	su - postgres -c "$BINARIES_DIR/$IMAGE_VERSION/bin/pg_upgrade \
		-b '$BINARIES_DIR/$CLUSTER_VERSION/bin' -B '$BINARIES_DIR/$IMAGE_VERSION/bin' \
		-d '$backup_target' -D '$PGDATA' \
		-o \"-c config_file=/etc/postgresql/postgresql.conf\" \
		-O \"-c config_file=/etc/postgresql/postgresql.conf\""

	[ -f "$backup_target/postgresql.conf" ] && cp "$backup_target/postgresql.conf" "$PGDATA"
	[ -f "$backup_target/pg_hba.conf" ] && cp -f "$backup_target/pg_hba.conf" "$PGDATA"

	bashio::log.info "Upgrade completed successfully."
	RESTART_NEEDED=true
}

check_for_reindex() {
	local log_tail
	log_tail=$(timeout 15 cat /proc/1/fd/1 | tail -n 5)
	echo "$log_tail" | grep -q "please use REINDEX to rebuild the index" || return 0

	bashio::log.warning "REINDEX needed, starting now"
	for db in $(get_user_databases); do
		psql -h "$DB_HOSTNAME" -p "$DB_PORT" -U "$DB_USERNAME" -d "$db" -v ON_ERROR_STOP=1 -c "REINDEX DATABASE $db;"
	done
}

main() {
	bashio::log.info "Checking for required PostgreSQL cluster upgrade before server start…"
	[ -f /config/database/PG_VERSION ] && upgrade_postgres_if_needed

	start_postgres
	bashio::log.info "Waiting for PostgreSQL to start…"
	wait_for_postgres
	restart_immich_addons_if_flagged

	# Drop legacy vectors extension (connect as $DB_USERNAME)
	su - postgres -c "psql -U \"$DB_USERNAME\" -d postgres -c 'DROP EXTENSION IF EXISTS vectors CASCADE;'"

	upgrade_extension_if_needed "vectors"
	upgrade_extension_if_needed "vchord"
	show_db_extensions

	if [ "$RESTART_NEEDED" = true ]; then
		bashio::log.warning "A critical update occurred. Restarting Immich add‑on(s) after DB restart."
		touch "$RESTART_FLAG_FILE"
		bashio::addon.restart
		exit 0
	fi

	if [ -d /config/backups ]; then
		echo "Cleaning /config/backups now that upgrade is done"
		rm -r /config/backups
	fi

	check_for_reindex &
	bashio::log.info "All initialization / version‑check steps completed successfully!"
}

main
