#!/usr/bin/env bashio
# shellcheck shell=bash
# shellcheck disable=SC2155,SC2016
set -e

###################################
# Export all addon options as env #
###################################

bashio::log.info "Setting variables"

# For all keys in options.json
JSONSOURCE="/data/options.json"

# Export keys as env variables
# echo "All addon options were exported as variables"
mapfile -t arr < <(jq -r 'keys[]' "${JSONSOURCE}")

for KEYS in "${arr[@]}"; do
    if [[ "${KEYS}" == "env_vars" ]]; then
        continue
    fi
    # export key
    VALUE=$(jq ."$KEYS" "${JSONSOURCE}")
    line="${KEYS}='${VALUE//[\"\']/}'"
    # text
    if bashio::config.false "verbose" || [[ "${KEYS}" == *"PASS"* ]]; then
        bashio::log.blue "${KEYS}=******"
    else
        bashio::log.blue "$line"
    fi
    # Use locally
    export "${KEYS}=${VALUE//[\"\']/}"
    # Export the variable to run scripts
    sed -i "1a export $line" /home/seafile/*.sh 2> /dev/null
    find /opt/seafile -name '*.sh' -print0 | xargs -0 sed -i "1a export $line"
done

#######################################
# Apply extra environment variables   #
#######################################

if jq -e '.env_vars? | length > 0' "${JSONSOURCE}" >/dev/null; then
    bashio::log.info "Applying env_vars"
    while IFS=$'\t' read -r ENV_NAME ENV_VALUE; do
        if [[ -z "${ENV_NAME}" || "${ENV_NAME}" == "null" ]]; then
            continue
        fi

        if bashio::config.false "verbose" || [[ "${ENV_NAME}" == *"PASS"* ]]; then
            bashio::log.blue "${ENV_NAME}=******"
        else
            bashio::log.blue "${ENV_NAME}=${ENV_VALUE}"
        fi

        export "${ENV_NAME}=${ENV_VALUE}"

        ENV_VALUE_ESCAPED=$(printf "%q" "${ENV_VALUE}")
        ENV_LINE="export ${ENV_NAME}=${ENV_VALUE_ESCAPED}"
        sed -i "1a ${ENV_LINE}" /home/seafile/*.sh 2>/dev/null
        find /opt/seafile -name '*.sh' -print0 | xargs -0 sed -i "1a ${ENV_LINE}"
    done < <(jq -r '.env_vars[] | [.name, .value] | @tsv' "${JSONSOURCE}")
fi

#################
# DATA_LOCATION #
#################

bashio::log.info "Setting data location"
DATA_LOCATION=$(bashio::config 'data_location')

echo "... check $DATA_LOCATION folder exists"
mkdir -p "$DATA_LOCATION"

echo "... setting permissions"
chown -R seafile:seafile "$DATA_LOCATION"

echo "... copy media files"
#cp -rnf /opt/seafile/media/* "$DATA_LOCATION"/media
#rm -r /opt/seafile/media

#echo "... creating symlink"
#dirs=("conf" "logs" "media" "seafile-data" "seahub-data" "sqlite")
#for dir in "${dirs[@]}"
#do
#   mkdir -p "$DATA_LOCATION/$dir"
#   chown -R seafile:seafile "$DATA_LOCATION/$dir"
#    ln -fs "$DATA_LOCATION/$dir" /shared
#    rm /shared/"$dir"
#done

echo "... correcting official script"
sed -i "s|/shared|$DATA_LOCATION|g" /docker_entrypoint.sh
sed -i "s|/shared|$DATA_LOCATION|g" /home/seafile/*.sh
#sed -i "s=cp -r ./media $DATA_LOCATION/=chown -R seafile:seafile $DATA_LOCATION/* && chmod -R 777 $DATA_LOCATION/media && cp -rnf ./media/. $DATA_LOCATION/media ||true=g" /home/seafile/*.sh

#####################
# Admin credentials #
#####################

# Seafile's check_init_admin.py looks for SEAFILE_ADMIN_EMAIL and
# SEAFILE_ADMIN_PASSWORD in the env, then falls back to conf/admin.txt, and
# only prompts interactively if neither is available. The upstream init.sh
# writes admin.txt, but it is skipped when conf/ccnet.conf or conf/revision
# already exist (e.g. after a partial previous install) and the env vars do
# not always reach the seahub subprocess via su. Write admin.txt directly and
# inject the values into seafile.env so admin creation succeeds (#2685).
ADMIN_EMAIL_VAL="$(bashio::config 'SEAFILE_ADMIN_EMAIL')"
ADMIN_PASSWORD_VAL="$(bashio::config 'SEAFILE_ADMIN_PASSWORD')"

if [[ -n "${ADMIN_EMAIL_VAL}" && "${ADMIN_EMAIL_VAL}" != "null" \
    && -n "${ADMIN_PASSWORD_VAL}" && "${ADMIN_PASSWORD_VAL}" != "null" ]]; then
    bashio::log.info "Seeding admin credentials"

    mkdir -p "${DATA_LOCATION}/conf"

    ADMIN_FILE="${DATA_LOCATION}/conf/admin.txt"
    jq -n --arg email "${ADMIN_EMAIL_VAL}" --arg password "${ADMIN_PASSWORD_VAL}" \
        '{email: $email, password: $password}' > "${ADMIN_FILE}"
    chown seafile:seafile "${ADMIN_FILE}"
    chmod 600 "${ADMIN_FILE}"

    SEAFILE_ENV_FILE="${DATA_LOCATION}/conf/seafile.env"
    touch "${SEAFILE_ENV_FILE}"
    sed -i '/^SEAFILE_ADMIN_EMAIL=/d' "${SEAFILE_ENV_FILE}"
    sed -i '/^SEAFILE_ADMIN_PASSWORD=/d' "${SEAFILE_ENV_FILE}"

    case "${ADMIN_EMAIL_VAL}" in
        *$'\n'*|*$'\r'*)
            bashio::exit.nok "SEAFILE_ADMIN_EMAIL must not contain newlines"
            ;;
    esac

    case "${ADMIN_PASSWORD_VAL}" in
        *$'\n'*|*$'\r'*)
            bashio::exit.nok "SEAFILE_ADMIN_PASSWORD must not contain newlines"
            ;;
    esac

    {
        printf 'SEAFILE_ADMIN_EMAIL=%s\n' "${ADMIN_EMAIL_VAL}"
        printf 'SEAFILE_ADMIN_PASSWORD=%s\n' "${ADMIN_PASSWORD_VAL}"
    } >> "${SEAFILE_ENV_FILE}"
    chown seafile:seafile "${SEAFILE_ENV_FILE}"
    chmod 600 "${SEAFILE_ENV_FILE}"
fi

#############################################
# Configure service URL and file server root #
#############################################

bashio::log.info "Configuring Seafile URLs"

SERVER_IP_CONFIG=$(bashio::config 'SERVER_IP')
SERVICE_URL_CONFIG=$(bashio::config 'url')
FILE_SERVER_ROOT_CONFIG=$(bashio::config 'FILE_SERVER_ROOT')

DEFAULT_HOST=${SERVER_IP_CONFIG:-homeassistant.local}

normalize_url() {
    local raw_url="${1%/}"
    local default_scheme="$2"

    if [[ -z "${raw_url}" || "${raw_url}" == "null" ]]; then
        echo ""
        return
    fi

    if [[ "${raw_url}" =~ ^https?:// ]]; then
        echo "${raw_url}"
    else
        echo "${default_scheme}://${raw_url}"
    fi
}

SERVICE_URL_VALUE=$(normalize_url "${SERVICE_URL_CONFIG:-${DEFAULT_HOST}:8000}" "http")

# FILE_SERVER_ROOT is optional; when empty Seafile derives it from SERVICE_URL
# (clients then reach the fileserver via the same reverse proxy path /seafhttp).
if [[ -n "${FILE_SERVER_ROOT_CONFIG}" && "${FILE_SERVER_ROOT_CONFIG}" != "null" ]]; then
    FILE_SERVER_ROOT_VALUE=$(normalize_url "${FILE_SERVER_ROOT_CONFIG}" "http")
else
    FILE_SERVER_ROOT_VALUE=""
fi

# Extract hostname and protocol for seafile.env
SERVER_PROTOCOL="${SERVICE_URL_VALUE%%://*}"
SERVER_HOSTNAME="${SERVICE_URL_VALUE#*://}"
SERVER_HOSTNAME="${SERVER_HOSTNAME%%/*}"
SERVER_HOSTNAME="${SERVER_HOSTNAME%%:*}"

SEAHUB_CONF_DIRS=()
if [[ -d "${DATA_LOCATION}/conf" || ! -d "${DATA_LOCATION}/seafile/conf" ]]; then
    SEAHUB_CONF_DIRS+=("${DATA_LOCATION}/conf")
fi
if [[ -d "${DATA_LOCATION}/seafile/conf" ]]; then
    SEAHUB_CONF_DIRS+=("${DATA_LOCATION}/seafile/conf")
fi
if [[ "${#SEAHUB_CONF_DIRS[@]}" -eq 0 ]]; then
    SEAHUB_CONF_DIRS+=("${DATA_LOCATION}/conf")
fi

for conf_dir in "${SEAHUB_CONF_DIRS[@]}"; do
    SEAHUB_SETTINGS_FILE="${conf_dir}/seahub_settings.py"
    mkdir -p "${conf_dir}"
    touch "${SEAHUB_SETTINGS_FILE}"

    sed -i '/^SERVICE_URL *=/d' "${SEAHUB_SETTINGS_FILE}"
    sed -i '/^FILE_SERVER_ROOT *=/d' "${SEAHUB_SETTINGS_FILE}"
    sed -i '/^CSRF_TRUSTED_ORIGINS *=/d' "${SEAHUB_SETTINGS_FILE}"

    echo "SERVICE_URL = \"${SERVICE_URL_VALUE}\"" >> "${SEAHUB_SETTINGS_FILE}"
    if [[ -n "${FILE_SERVER_ROOT_VALUE}" ]]; then
        echo "FILE_SERVER_ROOT = \"${FILE_SERVER_ROOT_VALUE}\"" >> "${SEAHUB_SETTINGS_FILE}"
    fi
    echo "CSRF_TRUSTED_ORIGINS = [\"${SERVICE_URL_VALUE}\"]" >> "${SEAHUB_SETTINGS_FILE}"
done

bashio::log.info "SERVICE_URL set to ${SERVICE_URL_VALUE}"
if [[ -n "${FILE_SERVER_ROOT_VALUE}" ]]; then
    bashio::log.info "FILE_SERVER_ROOT set to ${FILE_SERVER_ROOT_VALUE}"
else
    bashio::log.info "FILE_SERVER_ROOT not set; Seafile will derive it from SERVICE_URL"
fi
bashio::log.info "CSRF_TRUSTED_ORIGINS set to [\"${SERVICE_URL_VALUE}\"]"

#############################################
# Configure seafile.env (hostname/protocol) #
#############################################

bashio::log.info "Configuring seafile.env (SEAFILE_SERVER_HOSTNAME=${SERVER_HOSTNAME}, SEAFILE_SERVER_PROTOCOL=${SERVER_PROTOCOL})"

for conf_dir in "${SEAHUB_CONF_DIRS[@]}"; do
    SEAFILE_ENV_FILE="${conf_dir}/seafile.env"
    touch "${SEAFILE_ENV_FILE}"
    chown seafile:seafile "${SEAFILE_ENV_FILE}" 2>/dev/null || true
    chmod 600 "${SEAFILE_ENV_FILE}"
    sed -i '/^SEAFILE_SERVER_HOSTNAME=/d' "${SEAFILE_ENV_FILE}"
    sed -i '/^SEAFILE_SERVER_PROTOCOL=/d' "${SEAFILE_ENV_FILE}"
    {
        printf 'SEAFILE_SERVER_HOSTNAME=%s\n' "${SERVER_HOSTNAME}"
        printf 'SEAFILE_SERVER_PROTOCOL=%s\n' "${SERVER_PROTOCOL}"
    } >> "${SEAFILE_ENV_FILE}"
done

#############################################
# Configure fileserver binding (0.0.0.0)   #
#############################################

bashio::log.info "Setting fileserver host to 0.0.0.0 in seafile.conf"

for conf_dir in "${SEAHUB_CONF_DIRS[@]}"; do
    SEAFILE_CONF="${conf_dir}/seafile.conf"
    mkdir -p "${conf_dir}"
    if [[ -f "${SEAFILE_CONF}" ]]; then
        if grep -q '^\[fileserver\]' "${SEAFILE_CONF}"; then
            sed -i '/^\[fileserver\]/,/^\[/{/^host *=/d}' "${SEAFILE_CONF}"
            sed -i '/^\[fileserver\]/a host = 0.0.0.0' "${SEAFILE_CONF}"
        else
            printf '\n[fileserver]\nhost = 0.0.0.0\n' >> "${SEAFILE_CONF}"
        fi
    else
        printf '[fileserver]\nhost = 0.0.0.0\n' > "${SEAFILE_CONF}"
        chown seafile:seafile "${SEAFILE_CONF}" 2>/dev/null || true
    fi
done

# The upstream write_config.sh hardcodes /seafhttp in FILE_SERVER_ROOT and
# overwrites our settings on first run.  Create a helper that re-applies the
# addon's URL configuration right before Seafile services start, so it always
# takes effect regardless of what the upstream init/setup scripts wrote.

# Pre-compute the conditional FILE_SERVER_ROOT line for the generated script.
_fsr_apply_line="# FILE_SERVER_ROOT not set; Seafile will derive it from SERVICE_URL"
if [[ -n "${FILE_SERVER_ROOT_VALUE}" ]]; then
    _fsr_apply_line="        echo 'FILE_SERVER_ROOT = \"${FILE_SERVER_ROOT_VALUE}\"' >> \"\$_CONF\""
fi

cat > /home/seafile/apply_addon_urls.sh << URLEOF
#!/bin/bash
for _CONF in "${DATA_LOCATION}/conf/seahub_settings.py" "${DATA_LOCATION}/seafile/conf/seahub_settings.py"; do
    if [ -f "\$_CONF" ]; then
        sed -i '/^SERVICE_URL *=/d' "\$_CONF"
        sed -i '/^FILE_SERVER_ROOT *=/d' "\$_CONF"
        sed -i '/^CSRF_TRUSTED_ORIGINS *=/d' "\$_CONF"
        echo 'SERVICE_URL = "${SERVICE_URL_VALUE}"' >> "\$_CONF"
        ${_fsr_apply_line}
        echo 'CSRF_TRUSTED_ORIGINS = ["${SERVICE_URL_VALUE}"]' >> "\$_CONF"
    fi
done
for _ENV in "${DATA_LOCATION}/conf/seafile.env" "${DATA_LOCATION}/seafile/conf/seafile.env"; do
    if [ -f "\$_ENV" ]; then
        sed -i '/^SEAFILE_SERVER_HOSTNAME=/d' "\$_ENV"
        sed -i '/^SEAFILE_SERVER_PROTOCOL=/d' "\$_ENV"
        printf 'SEAFILE_SERVER_HOSTNAME=${SERVER_HOSTNAME}\n' >> "\$_ENV"
        printf 'SEAFILE_SERVER_PROTOCOL=${SERVER_PROTOCOL}\n' >> "\$_ENV"
    fi
done
for _SCONF in "${DATA_LOCATION}/conf/seafile.conf" "${DATA_LOCATION}/seafile/conf/seafile.conf"; do
    if [ -f "\$_SCONF" ]; then
        if grep -q '^\[fileserver\]' "\$_SCONF"; then
            sed -i '/^\[fileserver\]/,/^\[/{/^host *=/d}' "\$_SCONF"
            sed -i '/^\[fileserver\]/a host = 0.0.0.0' "\$_SCONF"
        else
            printf '\n[fileserver]\nhost = 0.0.0.0\n' >> "\$_SCONF"
        fi
    fi
done
URLEOF
chmod +x /home/seafile/apply_addon_urls.sh
sed -i '/print "Launching seafile"/i /home/seafile/apply_addon_urls.sh' /home/seafile/launch.sh
if ! grep -q 'apply_addon_urls.sh' /home/seafile/launch.sh 2>/dev/null; then
    bashio::log.warning "Could not inject URL configuration into launch.sh; URLs may use upstream defaults"
fi

###################
# Define database #
###################

bashio::log.info "Defining database"

# The option is defined as a list, so grab the first entry when an array is
# provided (Home Assistant stores multi-select options this way). Fallback to
# the raw value to stay compatible with older configurations that used a
# string.
DATABASE_SELECTION=$(bashio::config 'database[0]' 2>/dev/null || true)
DATABASE_SELECTION=${DATABASE_SELECTION:-$(bashio::config 'database')}

case "${DATABASE_SELECTION}" in

    # Use sqlite
    sqlite)
        export "SQLITE=1" && sed -i "1a export SQLITE=1" /home/seafile/*.sh
        ;;

        # Use mariadb
    mariadb_addon)
        bashio::log.info "Using MariaDB addon. Requirements : running MariaDB addon. Discovering values..."
        if ! bashio::services.available 'mysql'; then
            bashio::log.fatal \
                "Local database access should be provided by the MariaDB addon"
            bashio::exit.nok \
                "Please ensure it is installed and started"
        fi

        # Resolve MariaDB hostname to IPv4: on HAOS >=17.3 the Supervisor network
        # gained IPv6, but the MariaDB addon only grants its user from the IPv4
        # subnet (issue #2688). Fall back to the raw hostname if resolution fails.
        mariadb_host_raw="$(bashio::services 'mysql' 'host')"
        mariadb_host_ipv4="$(getent ahostsv4 "$mariadb_host_raw" 2> /dev/null | awk '{print $1; exit}')"
        MYSQL_HOST_RESOLVED="${mariadb_host_ipv4:-$mariadb_host_raw}"
        if [ "$MYSQL_HOST_RESOLVED" != "$mariadb_host_raw" ]; then
            bashio::log.info "Resolved ${mariadb_host_raw} -> ${MYSQL_HOST_RESOLVED} (forcing IPv4)"
        fi

        # Use values
        export MYSQL_HOST="$MYSQL_HOST_RESOLVED" && sed -i "1a export MYSQL_HOST=${MYSQL_HOST_RESOLVED}" /home/seafile/*.sh
        export MYSQL_PORT="$(bashio::services 'mysql' 'port')" && sed -i "1a export MYSQL_PORT=$(bashio::services 'mysql' 'port')" /home/seafile/*.sh
        export MYSQL_USER="$(bashio::services "mysql" "username")" && sed -i "1a export MYSQL_USER=$(bashio::services 'mysql' 'username')" /home/seafile/*.sh
        export MYSQL_USER_PASSWD="$(bashio::services "mysql" "password")" && sed -i "1a export MYSQL_USER_PASSWD=$(bashio::services 'mysql' 'password')" /home/seafile/*.sh
        export MYSQL_ROOT_PASSWD="$(bashio::services "mysql" "password")" && sed -i "1a export MYSQL_ROOT_PASSWD=$(bashio::services 'mysql' 'password')" /home/seafile/*.sh

        # Mariadb requires a user
        echo "Adapting scripts"
        sed -i 's|port=${MYSQL_PORT})|port=${MYSQL_PORT}, user="${MYSQL_USER}")|g' /home/seafile/wait_for_db.sh

        # Mariadb has no root user
        echo "Adapting root name"
        sed -i 's|user="root"|user="service"|g' /home/seafile/clean_db.sh
        sed -i "s|'root'|'service'|g" /opt/seafile/*/setup-seafile-mysql.sh
        sed -i "s|'root'|'service'|g" /opt/seafile/*/setup-seafile-mysql.py

        # Informations
        bashio::log.warning "This addon is using the Maria DB addon"
        bashio::log.warning "Please ensure this is included in your backups"
        bashio::log.warning "Uninstalling the MariaDB addon will remove any data"
        ;;
esac

##############
# LAUNCH APP #
##############

bashio::log.info "Starting app"
/./docker_entrypoint.sh launch
