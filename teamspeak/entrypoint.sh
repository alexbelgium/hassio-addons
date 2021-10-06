#!/bin/sh
set -e

# don't start ts3server with root permissions
if [ "$1" = 'ts3server' -a "$(id -u)" = '0' ]; then
    chown -R ts3server /var/ts3server
    exec su-exec ts3server "$0" "$@"
fi

# have the default inifile as the last parameter
if [ "$1" = 'ts3server' ]; then
    set -- "$@" inifile=/var/run/ts3server/ts3server.ini
fi

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
# "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    eval local varValue="\$${var}"
    eval local fileVarValue="\$${var}_FILE"
    local def="${2:-}"
    if [ "${varValue:-}" ] && [ "${fileVarValue:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${varValue:-}" ]; then
        val="${varValue}"
    elif [ "${fileVarValue:-}" ]; then
        val="$(cat "${fileVarValue}")"
    fi
    export "$var"="$val"
    if [ "${fileVar:-}" ]; then
        unset "$fileVar"
    fi
    if [ "${fileVarValue:-}" ]; then
        unset "fileVarValue"
    fi
}

if [ "$1" = 'ts3server' ]; then
    file_env 'TS3SERVER_DB_HOST'
    file_env 'TS3SERVER_DB_USER'
    file_env 'TS3SERVER_DB_PASSWORD'
    file_env 'TS3SERVER_DB_NAME'

    cat << EOF | sed 's/^[ \t]*//;s/[ \t]*$//;/^$/d' > /var/run/ts3server/ts3server.ini
        licensepath=${TS3SERVER_LICENSEPATH}
        query_protocols=${TS3SERVER_QUERY_PROTOCOLS:-raw}
        query_timeout=${TS3SERVER_QUERY_TIMEOUT:-300}
        query_ssh_rsa_host_key=${TS3SERVER_QUERY_SSH_RSA_HOST_KEY:-ssh_host_rsa_key}
        query_ip_allowlist=${TS3SERVER_IP_ALLOWLIST:-query_ip_allowlist.txt}
        query_ip_blocklist=${TS3SERVER_IP_BLOCKLIST:-query_ip_blocklist.txt}
        dbplugin=${TS3SERVER_DB_PLUGIN:-ts3db_sqlite3}
        dbpluginparameter=${TS3SERVER_DB_PLUGINPARAMETER:-/var/run/ts3server/ts3db.ini}
        dbsqlpath=${TS3SERVER_DB_SQLPATH:-/opt/ts3server/sql/}
        dbsqlcreatepath=${TS3SERVER_DB_SQLCREATEPATH:-create_sqlite}
        dbconnections=${TS3SERVER_DB_CONNECTIONS:-10}
        dbclientkeepdays=${TS3SERVER_DB_CLIENTKEEPDAYS:-30}
        logpath=${TS3SERVER_LOG_PATH:-/var/ts3server/logs}
        logquerycommands=${TS3SERVER_LOG_QUERY_COMMANDS:-0}
        logappend=${TS3SERVER_LOG_APPEND:-0}
        serverquerydocs_path=${TS3SERVER_SERVERQUERYDOCS_PATH:-/opt/ts3server/serverquerydocs/}
        ${TS3SERVER_QUERY_IP:+query_ip=${TS3SERVER_QUERY_IP}}
        query_port=${TS3SERVER_QUERY_PORT:-10011}
        ${TS3SERVER_FILETRANSFER_IP:+filetransfer_ip=${TS3SERVER_FILETRANSFER_IP}}
        filetransfer_port=${TS3SERVER_FILETRANSFER_PORT:-30033}
        ${TS3SERVER_VOICE_IP:+voice_ip=${TS3SERVER_VOICE_IP}}
        default_voice_port=${TS3SERVER_DEFAULT_VOICE_PORT:-9987}
        ${TS3SERVER_QUERY_SSH_IP:+query_ssh_ip=${TS3SERVER_QUERY_SSH_IP}}
        query_ssh_port=${TS3SERVER_QUERY_SSH_PORT:-10022}
        ${TS3SERVER_SERVERADMIN_PASSWORD:+serveradmin_password=${TS3SERVER_SERVERADMIN_PASSWORD}}
        ${TS3SERVER_MACHINE_ID:+machine_id=${TS3SERVER_MACHINE_ID}}
        ${TS3SERVER_QUERY_SKIPBRUTEFORCECHECK:+query_skipbruteforcecheck=${TS3SERVER_QUERY_SKIPBRUTEFORCECHECk}}
        ${TS3SERVER_HINTS_ENABLED:+hints_enabled=${TS3SERVER_HINTS_ENABLED}}
EOF

    cat << EOF | sed 's/^[ \t]*//;s/[ \t]*$//;/^$/d' > /var/run/ts3server/ts3db.ini
        [config]
        host='${TS3SERVER_DB_HOST}'
        port='${TS3SERVER_DB_PORT:-3306}'
        username='${TS3SERVER_DB_USER}'
        password='${TS3SERVER_DB_PASSWORD}'
        database='${TS3SERVER_DB_NAME}'
        socket=
        wait_until_ready='${TS3SERVER_DB_WAITUNTILREADY:-30}'
EOF
fi

exec "$@"
