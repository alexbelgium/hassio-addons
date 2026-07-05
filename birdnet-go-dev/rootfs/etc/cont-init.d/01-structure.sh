#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Default Variables
DEFAULT_BIRDSONGS_FOLDER="/data/clips"
CONFIG_LOCATION="/config/config.yaml"

# Strip trailing slashes; canonical internal form has none.
normalize_path() {
    local p="$1"
    while [[ "$p" == */ && "$p" != "/" ]]; do
        p="${p%/}"
    done
    printf '%s' "$p"
}

# Reject paths containing characters that would break the SQL/YAML literals
# we substitute into below. We deliberately allow only "safe" filename chars.
validate_safe_path() {
    local p="$1"
    if [[ ! "$p" =~ ^[A-Za-z0-9._/-]+$ ]]; then
        bashio::log.fatal "Refusing unsafe path: '$p' (only [A-Za-z0-9._/-] allowed)"
        exit 1
    fi
}

if [ ! -f "$CONFIG_LOCATION" ]; then
    bashio::log.warning "There is no config.yaml yet in the config folder, downloading a default one. Please customize"
    # Network may be unreachable on first boot. If the download fails, seed
    # an empty YAML document so the yq reads/writes below succeed and the
    # default-value seeding logic later in this script populates a usable
    # config. (We can't remove the file and continue — subsequent yq calls
    # under set -e would abort the init script.)
    if ! curl -fL -s -S \
            https://raw.githubusercontent.com/tphakala/birdnet-go/refs/heads/main/internal/conf/config.yaml \
            -o "$CONFIG_LOCATION"; then
        bashio::log.warning "Could not download default config.yaml; seeding an empty document so addon defaults can populate it"
        echo '{}' > "$CONFIG_LOCATION"
    fi
fi

#################
# Migrate Database
#################
if [ -f /data/birdnet.db ]; then
    bashio::log.warning "Moving birdnet.db to /config/birdnet.db"
    mv /data/birdnet.db /config
fi

######################
# Birdsongs Location
######################
# Read the current folder from config.yaml; "// """ collapses both missing
# keys and explicit nulls (e.g. in a freshly seeded "{}" doc) to an empty
# string so the ${VAR:-DEFAULT} fallback below kicks in.
CURRENT_BIRDSONGS_FOLDER="$(yq -r '.realtime.audio.export.path // ""' "$CONFIG_LOCATION")"
CURRENT_BIRDSONGS_FOLDER="${CURRENT_BIRDSONGS_FOLDER:-$DEFAULT_BIRDSONGS_FOLDER}"
# Treat the upstream-shipped relative "clips/" as the legacy default.
if [[ "$CURRENT_BIRDSONGS_FOLDER" == "clips" || "$CURRENT_BIRDSONGS_FOLDER" == "clips/" ]]; then
    CURRENT_BIRDSONGS_FOLDER="$DEFAULT_BIRDSONGS_FOLDER"
fi
CURRENT_BIRDSONGS_FOLDER="$(normalize_path "$CURRENT_BIRDSONGS_FOLDER")"

# Set the new birdsongs folder from addon options (default: relative "clips").
BIRDSONGS_FOLDER="$(bashio::config "BIRDSONGS_FOLDER")"
BIRDSONGS_FOLDER="$(normalize_path "${BIRDSONGS_FOLDER:-clips}")"

validate_safe_path "$BIRDSONGS_FOLDER"
validate_safe_path "$CURRENT_BIRDSONGS_FOLDER"

if [[ ! "$BIRDSONGS_FOLDER" == /* ]]; then
    if [ ! -d "/config/$BIRDSONGS_FOLDER" ]; then
        mkdir -p "/config/$BIRDSONGS_FOLDER"
    fi
    if [ -d "/data/$BIRDSONGS_FOLDER" ]; then
        if [ -n "$(ls -A /data/"$BIRDSONGS_FOLDER" 2> /dev/null)" ]; then
            cp -rf /data/"$BIRDSONGS_FOLDER"/* "/config/$BIRDSONGS_FOLDER"/
        fi
        rm -r "/data/$BIRDSONGS_FOLDER"
    fi
    ln -sf "/config/$BIRDSONGS_FOLDER" "/data/$BIRDSONGS_FOLDER"
fi

bashio::log.info "... audio clips saved to $BIRDSONGS_FOLDER according to addon options"

# Migrate data if the folder has changed
if [[ "$CURRENT_BIRDSONGS_FOLDER" != "$BIRDSONGS_FOLDER" ]]; then
    bashio::log.warning "Birdsongs folder changed from $CURRENT_BIRDSONGS_FOLDER to $BIRDSONGS_FOLDER"
    # Update config.yaml with the new birdsongs folder path (trailing slash
    # restored only at the boundary, since birdnet-go expects it).
    yq -i -y ".realtime.audio.export.path = \"${BIRDSONGS_FOLDER}/\"" "$CONFIG_LOCATION"
    # Move files only if sqlite paths changed
    if [[ -d "$CURRENT_BIRDSONGS_FOLDER" && "$(ls -A "$CURRENT_BIRDSONGS_FOLDER")" ]]; then
        bashio::log.warning "Migrating files from $CURRENT_BIRDSONGS_FOLDER to $BIRDSONGS_FOLDER"
        # The absolute-path target (e.g. the default /config/clips) is never
        # created by the relative-path block above, so ensure it exists before
        # copying into it; otherwise cp aborts the init script under set -e.
        mkdir -p "$BIRDSONGS_FOLDER"
        cp -rnf "$CURRENT_BIRDSONGS_FOLDER"/* "$BIRDSONGS_FOLDER"/
        mv "$CURRENT_BIRDSONGS_FOLDER" "${CURRENT_BIRDSONGS_FOLDER}_migrated"
    fi
    # Adapt the database
    if [ -f /config/birdnet.db ]; then
        backup="$(date +%Y%m%d_%H%M%S)"
        BACKUP_FILE="/config/birdnet.db_${backup}"
        bashio::log.warning "Modifying database paths from $CURRENT_BIRDSONGS_FOLDER to $BIRDSONGS_FOLDER. A backup will be created at ${BACKUP_FILE}"

        # Create backup at the absolute path we'll restore from on failure.
        if ! cp /config/birdnet.db "$BACKUP_FILE"; then
            bashio::log.error "Failed to create a backup of the database. Aborting path modification."
            exit 1
        fi

        # Paths were validated above against [A-Za-z0-9._/-]+ so quote
        # escaping in the SQL literal is not a concern.
        SQL_QUERY="UPDATE notes SET clip_name = '${BIRDSONGS_FOLDER}/' || substr(clip_name, length('${CURRENT_BIRDSONGS_FOLDER}/') + 1) WHERE clip_name LIKE '${CURRENT_BIRDSONGS_FOLDER}/%';"

        if ! sqlite3 /config/birdnet.db "$SQL_QUERY"; then
            bashio::log.warning "An error occurred while updating the paths. The database backup will be restored."
            if [ -f "$BACKUP_FILE" ]; then
                mv "$BACKUP_FILE" /config/birdnet.db
                bashio::log.info "The database backup has been restored."
            else
                bashio::log.error "Backup file $BACKUP_FILE not found! Manual intervention required."
            fi
        else
            bashio::log.info "Paths have been successfully updated."
        fi
    fi
fi

####################
# Correct Defaults
####################
# Seed addon-specific defaults only if the user has not set them in
# config.yaml. The "//=" form leaves any user-edited value alone, so
# changes made via the BirdNET-Go UI or by hand-editing /config/config.yaml
# survive container restarts.
bashio::log.info "Seeding default configuration values (only if missing)"

yq -i -y '.output.sqlite.path //= "/config/birdnet.db"' "$CONFIG_LOCATION"

####################
# Log Management
####################
LOG_MAX_SIZE_MB="$(bashio::config "LOG_MAX_SIZE_MB")"
LOG_MAX_SIZE_MB="${LOG_MAX_SIZE_MB:-50}"
LOG_MAX_AGE_DAYS="$(bashio::config "LOG_MAX_AGE_DAYS")"
LOG_MAX_AGE_DAYS="${LOG_MAX_AGE_DAYS:-7}"

bashio::log.info "Seeding default log rotation: max ${LOG_MAX_SIZE_MB}MB per file, max ${LOG_MAX_AGE_DAYS} days retention (only applied if not already set)"

# Seed log-rotation defaults; do not clobber user-edited values.
yq -i -y ".logging.file_output.max_size //= ${LOG_MAX_SIZE_MB}" "$CONFIG_LOCATION"
yq -i -y ".logging.file_output.max_age //= ${LOG_MAX_AGE_DAYS}" "$CONFIG_LOCATION"
yq -i -y '.logging.file_output.max_rotated_files //= 3' "$CONFIG_LOCATION"
yq -i -y '.logging.file_output.compress //= true' "$CONFIG_LOCATION"

# Trim existing log files that exceed the configured max age
LOG_DIR="/config/logs"
if [ -d "$LOG_DIR" ]; then
    bashio::log.info "Trimming log files older than ${LOG_MAX_AGE_DAYS} days in ${LOG_DIR}"
    ln -sf "$LOG_DIR" /logs
    find "$LOG_DIR" -type f -name "*.log*" -mtime +"$LOG_MAX_AGE_DAYS" -delete 2>/dev/null || true
fi
