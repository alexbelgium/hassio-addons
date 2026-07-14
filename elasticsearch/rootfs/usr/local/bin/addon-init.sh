#!/bin/bash
# shellcheck shell=bash
# Sourced by /usr/local/bin/docker-entrypoint.sh (right after "set -e"),
# before Elasticsearch starts. The container starts as root (see
# Dockerfile) so this script can chown/move pre-existing /data content
# that may be owned by root from earlier installs. Elasticsearch itself
# refuses to run as root, and unlike 7.x the upstream 8.x entrypoint no
# longer drops privileges on its own, so this script does it at the end
# (section 6) by re-execing the entrypoint as uid 1000. On that re-exec'd
# pass this script just returns immediately (see the guard right below).
#
# Responsibilities:
#   1. Export user env_vars from /data/options.json
#   2. Default xpack.security.enabled=false (7.x behavior) unless user overrides
#   3. Relocate data & config to /data for persistence (idempotent)
#   4. Guard major-version data migrations (7.x -> 8.x is automatic)
#   5. Record the running version once Elasticsearch is confirmed healthy
#   6. Drop root privileges before Elasticsearch actually starts

if [ -n "${_ADDON_INIT_REEXEC:-}" ]; then
    return 0
fi

echo "-----------------------------------------------------------"
echo " Add-on: Elasticsearch server"
echo " Upstream version: ${UPSTREAM_VERSION:-unknown}"
echo "-----------------------------------------------------------"

ES_HOME="/usr/share/elasticsearch"
PERSISTENT_HOME="/data"
VERSION_MARKER="$PERSISTENT_HOME/.addon-upstream-version"
OPTIONS_JSON="/data/options.json"

############################
# 1 Export user env_vars   #
############################

if [ -f "$OPTIONS_JSON" ] && command -v jq >/dev/null 2>&1; then
    while IFS= read -r pair; do
        name=$(jq -r '.name // empty' <<<"$pair")
        value=$(jq -r '.value // empty' <<<"$pair")
        if [[ $name =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
            echo "Setting env variable from options: $name"
            export "$name"="$value"
        elif [ -n "$name" ]; then
            echo "WARNING: ignoring invalid env_vars name: $name"
        fi
    done < <(jq -c '.env_vars[]?' "$OPTIONS_JSON" 2>/dev/null || true)
fi

##################################
# 2 Security default (7.x parity)#
##################################

# ES 8+ enables security + TLS by default, which breaks plain-http clients
# such as the homeassistant-elasticsearch component. Keep the previous 7.x
# behavior unless the user explicitly configures xpack.security themselves
# (either as a dotted setting or via the ES_SETTING_* translation).
if ! env | grep -qiE '^(xpack\.security\.|ES_SETTING_XPACK_SECURITY_)'; then
    export ES_SETTING_XPACK_SECURITY_ENABLED=false
    echo "Security: xpack.security.enabled=false (default; override by setting ES_SETTING_XPACK_SECURITY_ENABLED in env_vars)"
fi

############################
# 3 Migration guard        #
############################

current_version="${UPSTREAM_VERSION:-0.0.0}"
current_major="${current_version%%.*}"
data_version=""

if [ -f "$VERSION_MARKER" ]; then
    data_version="$(head -n 1 "$VERSION_MARKER" | tr -cd '0-9.')"
elif [ -d "$PERSISTENT_HOME/data" ] && [ -n "$(ls -A "$PERSISTENT_HOME/data" 2>/dev/null)" ]; then
    # Existing data without a marker: only 7.17.9 was ever shipped before markers
    data_version="7.17.9"
fi

if [ -n "$data_version" ] && [[ $current_major =~ ^[0-9]+$ ]]; then
    data_major="${data_version%%.*}"
    if [ "$data_major" -gt "$current_major" ]; then
        echo "FATAL: existing data was written by Elasticsearch $data_version but this add-on runs $current_version."
        echo "Downgrading Elasticsearch data is not supported. Restore a Home Assistant snapshot taken with the newer version, or delete the add-on data to start fresh."
        exit 1
    elif [ "$((current_major - data_major))" -gt 1 ]; then
        echo "FATAL: existing data was written by Elasticsearch $data_version, which is more than one major version behind $current_version."
        echo "Elasticsearch can only upgrade data from the previous major version. Upgrade stepwise (e.g. $data_major.x -> $((data_major + 1)).x -> ...) or delete the add-on data to start fresh."
        exit 1
    elif [ "$data_major" -lt "$current_major" ]; then
        echo "NOTICE: one-time automatic data migration from Elasticsearch $data_version to $current_version."
        echo "NOTICE: indices are upgraded automatically on startup. This can take a while on large datasets - do NOT stop the add-on during the first start."
        # The bundled config from the old major is stale (jvm.options, log4j2,
        # security settings). Archive it so a fresh one is seeded below.
        if [ -d "$PERSISTENT_HOME/config" ] && [ ! -L "$PERSISTENT_HOME/config" ]; then
            config_backup="$PERSISTENT_HOME/config.bak-$data_version"
            if [ ! -e "$config_backup" ]; then
                mv "$PERSISTENT_HOME/config" "$config_backup"
                echo "NOTICE: previous config archived to $config_backup. Re-apply any custom settings to the new config."
            fi
        fi
        # The container config dir may still symlink to the archived config
        if [ -L "$ES_HOME/config" ]; then
            rm -f "$ES_HOME/config"
        fi
    fi
fi

############################
# 4 Data persistence       #
############################

mkdir -p "$PERSISTENT_HOME"
for dir in "data" "config"; do
    if [ ! -L "$ES_HOME/$dir" ]; then
        if [ -d "$ES_HOME/$dir" ]; then
            cp -rn "$ES_HOME/$dir" "$PERSISTENT_HOME" 2>/dev/null || true
            rm -rf "${ES_HOME:?}/$dir"
        fi
        mkdir -p "$PERSISTENT_HOME/$dir"
        ln -s "$PERSISTENT_HOME/$dir" "$ES_HOME/$dir"
    fi
done

# Make the persisted files usable by the elasticsearch user (uid 1000),
# which the official entrypoint drops to when started as root
if [ "$(id -u)" -eq 0 ]; then
    chown -R 1000:0 "$PERSISTENT_HOME/data" "$PERSISTENT_HOME/config" 2>/dev/null || true
fi

echo "Data location: $PERSISTENT_HOME (persistent). Please wait while elasticsearch starts..."

############################
# 5 Record data version    #
############################

# Only record the running version once ES is confirmed healthy, so a failed
# upgrade attempt never masks the true on-disk data lineage
if [ "$data_version" != "$current_version" ]; then
    (
        for _ in $(seq 1 180); do
            # Check the HTTP status directly instead of curl -f: a 401 means
            # Elasticsearch is up and answering (security just requires
            # auth), so it must count as healthy too, not as a failure.
            status=$(curl -A "HealthCheck: Docker/1.0" -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:9200" 2>/dev/null || true)
            if [ "$status" = "200" ] || [ "$status" = "401" ]; then
                echo "$current_version" >"$VERSION_MARKER"
                echo "Elasticsearch $current_version started successfully; data version recorded."
                exit 0
            fi
            sleep 10
        done
    ) &
fi

############################
# 6 Drop privileges        #
############################

# Elasticsearch refuses to start as root ("can not run elasticsearch as
# root"). 7.x's own entrypoint dropped to uid 1000 via chroot before
# launching Elasticsearch; 8.x no longer does that, so do it here instead,
# then let the entrypoint continue as uid 1000 (matches the sys_chroot /
# setuid / setgid capabilities already granted in the AppArmor profile).
if [ "$(id -u)" -eq 0 ]; then
    export _ADDON_INIT_REEXEC=1
    exec chroot --userspec=1000:0 / /usr/local/bin/docker-entrypoint.sh "$@"
fi
