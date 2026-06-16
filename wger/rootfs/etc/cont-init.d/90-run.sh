#!/usr/bin/env bashio

set -u

prepare_data_root() {
    mkdir -p /data
    chown wger /data || bashio::log.warning "Unable to set /data ownership to wger"
    chmod a+rwx /data || bashio::log.warning "Unable to make /data writable"
}

prepare_writable_dir() {
    local path="$1"

    mkdir -p "$path"
    chown -R wger "$path" || bashio::log.warning "Unable to set $path ownership to wger"
    chmod -R a+rwX "$path" || bashio::log.warning "Unable to make $path writable"
}

move_persistent_dir() {
    local source="$1"
    local target="$2"

    prepare_writable_dir "$target"

    if [ -d "$source" ] && [ ! -L "$source" ]; then
        if [ -n "$(ls -A "$source" 2> /dev/null)" ]; then
            cp -rnf "$source"/. "$target"/
        fi
        rm -rf "$source"
    fi

    ln -sfn "$target" "$source"
}

migrate_database() {
    local legacy_db=/home/wger/db/database.sqlite
    local persistent_db=/data/database.sqlite

    if [ -f "$persistent_db" ]; then
        bashio::log.info "Using existing persistent database at $persistent_db"
    elif [ -f "$legacy_db" ]; then
        bashio::log.info "Migrating legacy database from $legacy_db to $persistent_db"
        cp -n "$legacy_db" "$persistent_db"
    else
        bashio::log.info "No existing database found; wger will create a new persistent database at $persistent_db"
    fi

    if [ -f "$persistent_db" ]; then
        chown wger "$persistent_db" || bashio::log.warning "Unable to set $persistent_db ownership to wger"
        chmod a+rw "$persistent_db" || bashio::log.warning "Unable to make $persistent_db writable"
    fi
}

############################
# Change database location #
############################
echo "... set database path"
mapfile -t SETTINGS_FILES < <(grep -rl --include='*.py' '/home/wger/db/database.sqlite' /home 2> /dev/null || true)

if [ "${#SETTINGS_FILES[@]}" -gt 0 ]; then
    for settings_file in "${SETTINGS_FILES[@]}"; do
        sed -i "s|/home/wger/db/database.sqlite|/data/database.sqlite|g" "$settings_file"
    done
else
    bashio::log.warning "Unable to find Python settings containing database path under /home, skipping rewrite"
fi

#####################
# Adapt directories #
#####################
echo "... create directories"
prepare_data_root
migrate_database
move_persistent_dir /home/wger/static /data/static
move_persistent_dir /home/wger/media /data/media

#####################
# Align permissions #
#####################
echo "... align permissions"
prepare_writable_dir /data/static
prepare_writable_dir /data/media
migrate_database

echo "... add env variables"
(
    set -o posix
    export -p
) > /data/env.sh

if [ -f /.env ]; then
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        var="${line%%=*}"
        [[ "$var" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
        sed -i "/^export[[:space:]]\+$var=/d" /data/env.sh
        echo "export $line" >> /data/env.sh
    done < /.env
fi

chown wger /data/env.sh || bashio::log.warning "Unable to set /data/env.sh ownership to wger"
chmod 0644 /data/env.sh || bashio::log.warning "Unable to make /data/env.sh readable"

bashio::log.info "Starting nginx"
mkdir -p /run/nginx /var/log/nginx
if [ -f /run/nginx.pid ] && kill -0 "$(cat /run/nginx.pid)" 2> /dev/null; then
    bashio::log.info "nginx is already running"
elif nginx -t; then
    nginx &
else
    bashio::log.error "nginx configuration test failed"
    exit 1
fi

bashio::log.info "Starting entrypoint"
