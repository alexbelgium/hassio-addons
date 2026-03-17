#!/usr/bin/env bashio

bashio::log.info "Starting Immich Frame"

mkdir -p /config/Config

# Handle legacy installs where /config/Config was a symlink to /app/Config
if [ -L /config/Config ]; then
    bashio::log.info "Migrating legacy /config/Config symlink to real directory"
    mkdir -p /config/Config.migrate
    # Copy contents from the symlink target into the new real directory
    cp -a /config/Config/. /config/Config.migrate/ 2>/dev/null || true
    rm -f /config/Config
    mv /config/Config.migrate /config/Config
fi

if [ -d /app/Config ] && [ ! -L /app/Config ]; then
    cp -n /app/Config/* /config/Config/ 2>/dev/null || true
    rm -rf /app/Config
fi
if [ ! -e /app/Config ]; then
    ln -sf /config/Config /app/Config
fi

# ---- Settings.yaml generation ----
SETTINGS_FILE="/config/Config/Settings.yaml"

# Known account-level setting names (ImmichFrame v2 config)
ACCOUNT_KEYS=" ImmichServerUrl ApiKey ApiKeyFile Albums ExcludedAlbums People Tags ShowFavorites ShowMemories ShowArchived ShowVideos ImagesFromDays ImagesFromDate ImagesUntilDate Rating "
# Settings that accept comma-separated values and should become YAML lists
LIST_KEYS=" Albums ExcludedAlbums People Tags Webcalendars "

# Helper: check if word is in a space-padded list
in_list() { [[ "$2" == *" $1 "* ]]; }

# Helper: read a value from options.json handling booleans and nulls correctly
config_val() {
    jq -r "($1) as \$v | if \$v == null then \"\" else (\$v | tostring) end" /data/options.json 2>/dev/null
}
config_has() {
    jq -e "($1) != null" /data/options.json >/dev/null 2>&1
}

# Helper: write a YAML key-value pair with proper formatting
yaml_kv() {
    local indent="$1" key="$2" value="$3"

    # List-type settings -> YAML array
    if in_list "$key" "$LIST_KEYS"; then
        echo "${indent}${key}:"
        IFS=',' read -ra ITEMS <<< "$value"
        for item in "${ITEMS[@]}"; do
            item="$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            [ -n "$item" ] && echo "${indent}  - '${item//\'/\'\'}'"
        done
        return
    fi

    # Boolean
    if [ "$value" = "true" ] || [ "$value" = "false" ]; then
        echo "${indent}${key}: ${value}"
        return
    fi

    # Integer
    if [[ "$value" =~ ^-?[0-9]+$ ]]; then
        echo "${indent}${key}: ${value}"
        return
    fi

    # Float
    if [[ "$value" =~ ^-?[0-9]+\.[0-9]+$ ]]; then
        echo "${indent}${key}: ${value}"
        return
    fi

    # String (single-quoted with escaping)
    echo "${indent}${key}: '${value//\'/\'\'}'"
}

# ---- Classify env_vars into general vs account settings ----
declare -A GENERAL_ENVS
declare -A ACCOUNT_ENVS

ENV_COUNT=$(jq '.env_vars // [] | length' /data/options.json 2>/dev/null || echo 0)
if [ "$ENV_COUNT" -gt 0 ]; then
    bashio::log.info "Processing ${ENV_COUNT} env_var(s) for Settings.yaml"
fi
for idx in $(seq 0 $((ENV_COUNT - 1))); do
    ENAME=$(jq -r ".env_vars[${idx}].name" /data/options.json)
    EVALUE=$(jq -r ".env_vars[${idx}].value // \"\"" /data/options.json)
    [ -z "$ENAME" ] && continue
    [ -z "$EVALUE" ] && continue
    [ "$ENAME" = "TZ" ] && continue  # TZ is a system env var, not an ImmichFrame setting

    if in_list "$ENAME" "$ACCOUNT_KEYS"; then
        ACCOUNT_ENVS["$ENAME"]="$EVALUE"
        bashio::log.info "  env_var ${ENAME} -> Account setting"
    else
        GENERAL_ENVS["$ENAME"]="$EVALUE"
        bashio::log.info "  env_var ${ENAME} -> General setting"
    fi
done

# General options from the addon schema
GENERAL_SCHEMA_OPTS="Interval TransitionDuration ShowClock ClockFormat ClockDateFormat
    ShowProgressBar ShowPhotoDate PhotoDateFormat ShowImageDesc ShowPeopleDesc
    ShowTagsDesc ShowAlbumName ShowImageLocation ShowWeatherDescription
    ImageZoom ImagePan ImageFill PlayAudio PrimaryColor SecondaryColor Style
    Layout BaseFontSize Language WeatherApiKey UnitSystem WeatherLatLong
    ImageLocationFormat DownloadImages RenewImagesDuration RefreshAlbumPeopleInterval"

# Per-account options from the addon schema (besides ImmichServerUrl/ApiKey)
ACCOUNT_SCHEMA_OPTS="Albums ExcludedAlbums People Tags ShowFavorites ShowMemories
    ShowArchived ShowVideos ImagesFromDays ImagesFromDate ImagesUntilDate Rating"

# ---- Build Settings.yaml ----
{
    # -- General section --
    GENERAL_STARTED=false

    for opt in $GENERAL_SCHEMA_OPTS; do
        if config_has ".$opt"; then
            $GENERAL_STARTED || { echo "General:"; GENERAL_STARTED=true; }
            yaml_kv "  " "$opt" "$(config_val ".$opt")"
        fi
    done

    # Add general env_vars (skip if already set via schema option)
    for key in "${!GENERAL_ENVS[@]}"; do
        if ! config_has ".$key"; then
            $GENERAL_STARTED || { echo "General:"; GENERAL_STARTED=true; }
            yaml_kv "  " "$key" "${GENERAL_ENVS[$key]}"
        fi
    done

    # -- Accounts section --
    ACCOUNT_COUNT=$(jq '.Accounts // [] | length' /data/options.json 2>/dev/null || echo 0)

    if [ "$ACCOUNT_COUNT" -gt 0 ]; then
        bashio::log.info "Configuring ${ACCOUNT_COUNT} account(s) from Accounts list"
        echo "Accounts:"
        for i in $(seq 0 $((ACCOUNT_COUNT - 1))); do
            SRV="$(config_val ".Accounts[${i}].ImmichServerUrl")"
            KEY="$(config_val ".Accounts[${i}].ApiKey")"
            echo "  - ImmichServerUrl: '${SRV//\'/\'\'}'"
            echo "    ApiKey: '${KEY//\'/\'\'}'"

            for opt in $ACCOUNT_SCHEMA_OPTS; do
                if config_has ".Accounts[${i}].${opt}"; then
                    yaml_kv "    " "$opt" "$(config_val ".Accounts[${i}].${opt}")"
                fi
            done

            # Apply account-level env_vars (only if not already set in this account's schema)
            for key in "${!ACCOUNT_ENVS[@]}"; do
                in_list "$key" " ImmichServerUrl ApiKey " && continue
                if ! config_has ".Accounts[${i}].${key}"; then
                    yaml_kv "    " "$key" "${ACCOUNT_ENVS[$key]}"
                fi
            done

            bashio::log.info "  Account $((i + 1)): ${SRV}"
        done

    elif config_has '.ApiKey' && config_has '.ImmichServerUrl'; then
        bashio::log.info "Using single account configuration"
        SRV="$(config_val '.ImmichServerUrl')"
        KEY="$(config_val '.ApiKey')"
        echo "Accounts:"
        echo "  - ImmichServerUrl: '${SRV//\'/\'\'}'"
        echo "    ApiKey: '${KEY//\'/\'\'}'"

        # Apply account-level env_vars to the single account
        for key in "${!ACCOUNT_ENVS[@]}"; do
            in_list "$key" " ImmichServerUrl ApiKey " && continue
            yaml_kv "    " "$key" "${ACCOUNT_ENVS[$key]}"
        done

    elif [ -n "${ACCOUNT_ENVS[ImmichServerUrl]:-}" ] && [ -n "${ACCOUNT_ENVS[ApiKey]:-}" ]; then
        bashio::log.info "Using account configuration from env_vars"
        echo "Accounts:"
        echo "  - ImmichServerUrl: '${ACCOUNT_ENVS[ImmichServerUrl]//\'/\'\'}'"
        echo "    ApiKey: '${ACCOUNT_ENVS[ApiKey]//\'/\'\'}'"

        for key in "${!ACCOUNT_ENVS[@]}"; do
            in_list "$key" " ImmichServerUrl ApiKey " && continue
            yaml_kv "    " "$key" "${ACCOUNT_ENVS[$key]}"
        done
    else
        bashio::log.fatal "No accounts configured! Set either 'Accounts' list or both 'ApiKey' and 'ImmichServerUrl'"
        exit 1
    fi

} > "${SETTINGS_FILE}"
chmod 600 "${SETTINGS_FILE}"
bashio::log.info "Settings.yaml generated at ${SETTINGS_FILE}"

# Log contents (mask sensitive values)
bashio::log.info "--- Generated Settings.yaml ---"
sed -E 's/(ApiKey:).*/\1 *****/;s/(AuthenticationSecret:).*/\1 *****/' "${SETTINGS_FILE}" | while IFS= read -r line; do
    bashio::log.info "$line"
done
bashio::log.info "-------------------------------"

export IMMICHFRAME_CONFIG_PATH=/config/Config
exec dotnet ImmichFrame.WebApi.dll
