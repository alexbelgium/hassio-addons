#!/usr/bin/env bashio
# shellcheck shell=bash
set -eo pipefail

CONFIG_FILE="$(bashio::config 'CONFIG_LOCATION')"
CONFIG_DIR="$(dirname "${CONFIG_FILE}")"
RUNTIME_CONFIG="/data/config.env"

mkdir -p "${CONFIG_DIR}" /data

# Recover from an old add-on bug that could create config.env as a directory.
if [ -d "${CONFIG_FILE}" ]; then
    bashio::log.warning "Found a directory at ${CONFIG_FILE}; replacing it with a configuration file"
    rm -rf "${CONFIG_FILE}"
fi

if [ ! -f "${CONFIG_FILE}" ]; then
    install -m 0600 /templates/config.env "${CONFIG_FILE}"
    bashio::log.warning \
        "Created ${CONFIG_FILE}. Add account credentials there and restart the add-on if automatic login is required."
else
    bashio::log.info "Using configuration from ${CONFIG_FILE}"
fi

# The remaster reads /fgc/data/config.env. /fgc/data is linked to Home
# Assistant's persistent /data volume by the Dockerfile.
install -m 0600 "${CONFIG_FILE}" "${RUNTIME_CONFIG}"
sed -i 's/\r$//' "${RUNTIME_CONFIG}"

# Export values needed by the VNC entrypoint as well as by the Python app.
set -a
# shellcheck source=/dev/null
source "${RUNTIME_CONFIG}"
set +a

# The Home Assistant port mapping is intentionally kept at 6080 for a seamless
# upgrade from the previous add-on, even though the new upstream defaults to 7080.
if [ -n "${NOVNC_PORT:-}" ] && [ "${NOVNC_PORT}" != "6080" ]; then
    bashio::log.warning "NOVNC_PORT=${NOVNC_PORT} is not supported by the add-on port mapping; using 6080"
fi
export NOVNC_PORT="6080"
export VNC_PORT="5900"

# Absolute paths from the former image pointed to its Firefox profile. The
# replacement uses Chromium profiles and must start with a separate directory.
if [ "${BROWSER_DIR:-}" = "/data/data/browser" ]; then
    bashio::log.warning "Remapping legacy Firefox BROWSER_DIR to the remaster Chromium profile directory"
    export BROWSER_DIR="/fgc/data/browser"
fi
if [ "${SCREENSHOTS_DIR:-}" = "/data/data/screenshots" ]; then
    export SCREENSHOTS_DIR="/fgc/data/screenshots"
fi

append_store() {
    local store="${1}"
    local current="${2}"

    if [[ ",${current}," == *",${store},"* ]]; then
        printf '%s' "${current}"
    elif [ -n "${current}" ]; then
        printf '%s,%s' "${current}" "${store}"
    else
        printf '%s' "${store}"
    fi
}

legacy_commands_to_stores() {
    local commands="${1}"
    local selected=""
    local command=""
    local normalized=""
    local command_list=()

    IFS=';' read -ra command_list <<< "${commands}"
    for command in "${command_list[@]}"; do
        normalized="${command,,}"
        case "${normalized}" in
            *epic-games*|*epicgames*|*" epic "*)
                selected="$(append_store "epic" "${selected}")"
                ;;
            *prime-gaming*|*primegaming*|*" prime "*|*" amazon "*)
                selected="$(append_store "prime" "${selected}")"
                ;;
            *steam-games*|*" steam "*)
                selected="$(append_store "steam" "${selected}")"
                ;;
            *gamerpower*)
                selected="$(append_store "gamerpower" "${selected}")"
                ;;
            *" gog"*|gog*)
                selected="$(append_store "gog" "${selected}")"
                ;;
        esac
    done

    printf '%s' "${selected}"
}

# A non-empty STORES add-on option takes priority. Otherwise retain a STORES
# value from config.env, then fall back to translating the legacy commands.
STORES_OPTION="$(bashio::config 'STORES')"
if [ -n "${STORES_OPTION}" ]; then
    export STORES="${STORES_OPTION}"
elif [ -z "${STORES:-}" ]; then
    CMD_ARGUMENTS="$(bashio::config 'CMD_ARGUMENTS')"
    STORES="$(legacy_commands_to_stores "${CMD_ARGUMENTS}")"
    export STORES="${STORES:-epic,prime,gog}"
fi

bashio::log.info "Enabled stores: ${STORES:-epic,prime,gog}"

# Import claim history from vogler/free-games-claimer once. Legacy files and
# browser data are retained under /data/data for rollback and manual recovery.
/usr/local/bin/migrate_vogler_data.py

APP_COMMAND=(python3 /fgc/main.py)
if bashio::config.true 'RUN_ONCE'; then
    APP_COMMAND+=(--once)
    bashio::log.info "Starting a single claiming run (legacy-compatible mode)"

    set +e
    /usr/local/bin/docker-entrypoint.sh "${APP_COMMAND[@]}"
    exit_code=$?
    set -e

    if [ "${exit_code}" -ne 0 ]; then
        bashio::log.error "Free Games Claimer exited with status ${exit_code}"
    else
        bashio::log.info "Claiming run completed"
    fi

    bashio::log.info "Stopping the add-on"
    sleep 2
    bashio::addon.stop
    exit "${exit_code}"
fi

bashio::log.info "Starting the built-in scheduler"
exec /usr/local/bin/docker-entrypoint.sh "${APP_COMMAND[@]}"
