#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# coolwsd matches storage.wopi.alias_groups host/alias entries as regular
# expressions, so every dot has to be escaped with a single backslash. The value
# is typed by hand in the add-on options, where it is easy to end up with no
# escaping at all or with doubled backslashes, and a wrong pattern silently
# never matches: Collabora then refuses the Nextcloud host. Accept all three
# spellings and always hand coolwsd the canonical single-escaped form.
REGEX_METACHARACTERS='][(){}|*+?^$'
normalise_wopi_host() {
    local value="$1"

    # A value containing regex metacharacters was written by someone who knows
    # what they are doing, leave it exactly as-is.
    if [[ "$value" == *["$REGEX_METACHARACTERS"]* ]]; then
        printf '%s' "$value"
        return
    fi

    value="${value//\\/}"   # drop whatever escaping was typed, at any depth
    value="${value//./\\.}" # re-escape every dot exactly once
    printf '%s' "$value"
}

# server_name is a literal "hostname[:port]", not a regex and not a URL
normalise_server_name() {
    local value="$1"
    value="${value//\\/}"  # never escaped, drop backslashes if any were copied over
    value="${value#*://}"  # strip the scheme
    value="${value%%/*}"   # strip any path
    printf '%s' "$value"
}

for index in 1 2 3; do
    if bashio::config.has_value "aliasgroup${index}"; then
        aliasgroup="$(normalise_wopi_host "$(bashio::config "aliasgroup${index}")")"
        export "aliasgroup${index}=${aliasgroup}"
        bashio::log.info "Allowed Nextcloud host aliasgroup${index}: ${aliasgroup}"
    fi
done

if bashio::config.has_value 'server_name'; then
    server_name="$(normalise_server_name "$(bashio::config 'server_name')")"
    export server_name
elif bashio::config.has_value 'domain1'; then
    # domain1 predates server_name and was documented as "the Collabora external
    # domain", which is what server_name means to coolwsd. It was never actually
    # passed to Collabora, so honour it here rather than keep ignoring it.
    server_name="$(normalise_server_name "$(bashio::config 'domain1')")"
    export server_name
    bashio::log.warning "domain1 is deprecated, please use server_name instead"
fi
if [ -n "${server_name:-}" ]; then
    bashio::log.info "Collabora public hostname (server_name): ${server_name}"
fi

if bashio::config.has_value 'username'; then
    username="$(bashio::config 'username')"
    export username
fi

if bashio::config.has_value 'password'; then
    password="$(bashio::config 'password')"
    export password
fi

if bashio::config.has_value 'cert_domain'; then
    cert_domain="$(bashio::config 'cert_domain')"
    export cert_domain
fi

if bashio::config.has_value 'dictionaries'; then
    dictionaries="$(bashio::config 'dictionaries')"
    export dictionaries
fi

extra_params=""
if bashio::config.has_value 'extra_params'; then
    extra_params="$(bashio::config 'extra_params')"
fi

if bashio::config.true 'ssl'; then
    export DONT_GEN_SSL_CERT=true
    bashio::config.require.ssl
    certfile="$(bashio::config 'certfile')"
    keyfile="$(bashio::config 'keyfile')"
    if ! bashio::fs.file_exists "/ssl/${certfile}"; then
        bashio::log.error "Certificate file /ssl/${certfile} not found"
        exit 1
    fi
    if ! bashio::fs.file_exists "/ssl/${keyfile}"; then
        bashio::log.error "Key file /ssl/${keyfile} not found"
        exit 1
    fi
    cp -f "/ssl/${keyfile}" /etc/coolwsd/key.pem
    cp -f "/ssl/${certfile}" /etc/coolwsd/cert.pem
    cp -f "/ssl/${certfile}" /etc/coolwsd/ca-chain.cert.pem
    extra_params="${extra_params/--o:ssl.enable=false/}"
    extra_params="${extra_params} \
         --o:ssl.enable=true \
         --o:ssl.termination=false \
         --o:ssl.cert_file_path=/ssl/${certfile} \
         --o:ssl.key_file_path=/ssl/${keyfile} \
         --o:ssl.ca_file_path=/ssl/${certfile}"
elif [[ "$extra_params" != *ssl.termination* ]]; then
    # coolwsd defaults ssl.termination to false, so with ssl disabled it builds
    # http:// and ws:// URLs even when the browser reached it over https through
    # a reverse proxy, and the browser then refuses the connection.
    if bashio::config.true 'ssl_termination'; then
        extra_params="${extra_params} --o:ssl.termination=true"
    elif ! bashio::config.has_value 'ssl_termination'; then
        bashio::log.notice "If Collabora is reached over https through a reverse proxy, set ssl_termination to true"
    fi
fi

export extra_params

COOL_CONFIG="/etc/coolwsd/coolwsd.xml"
CONFIG_DEST="/config/coolwsd.xml"

mkdir -p /config
if [ ! -e "${CONFIG_DEST}" ]; then
    mv "${COOL_CONFIG}" "${CONFIG_DEST}"
    chown root:root "${CONFIG_DEST}"
    chmod 644 "${CONFIG_DEST}"
else
    rm -f "${COOL_CONFIG}"
fi
ln -sf "${CONFIG_DEST}" "${COOL_CONFIG}"

SYSTEMPLATE_DIR="/opt/cool/systemplate/etc"
if [ -d "${SYSTEMPLATE_DIR}" ]; then
    cp /etc/hosts "${SYSTEMPLATE_DIR}/hosts"
    cp /etc/hostname "${SYSTEMPLATE_DIR}/hostname" 2> /dev/null || true
    cp /etc/resolv.conf "${SYSTEMPLATE_DIR}/resolv.conf"
fi
chown -R 1001 /opt/cool/systemplate
chown -R 1001 /etc/coolwsd
chmod -R 755 /opt/cool/systemplate

bashio::log.info "Starting Collabora Online..."
# coolwsd refuses to run as root. The official image used to ship
# /start-collabora-online.sh, which is gone since it became distroless, so the
# add-on provides its own launcher. It reads everything from the environment,
# which su -p preserves.
export HOME=/opt/cool
su -p -s /bin/bash cool -c /usr/local/bin/collabora-run.sh
