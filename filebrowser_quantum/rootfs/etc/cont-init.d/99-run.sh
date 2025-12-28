#!/usr/bin/env bashio
# shellcheck shell=bash
set -e

############
# TIMEZONE #
############

if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    if [ -f /usr/share/zoneinfo/"$TIMEZONE" ]; then
        ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
        echo "$TIMEZONE" > /etc/timezone
    else
        bashio::log.fatal "$TIMEZONE not found, are you sure it is a valid timezone?"
    fi
fi

###################
# SSL CONFIG v1.0 #
###################

bashio::config.require.ssl
if bashio::config.true 'ssl'; then
    bashio::log.info "ssl enabled. If webui don't work, disable ssl or check your certificate paths"
    #set variables
    CERTFILE="/ssl/$(bashio::config 'certfile')"
    KEYFILE="/ssl/$(bashio::config 'keyfile')"
else
    CERTFILE=""
    KEYFILE=""
fi
export CERTFILE KEYFILE

#################
# NGINX SETTING #
#################

#declare port
#declare certfile
declare ingress_interface
declare ingress_port
#declare keyfile

FB_BASEURL=$(bashio::addon.ingress_entry)
export FB_BASEURL

declare ADDON_PROTOCOL=http
# Generate Ingress configuration
if bashio::config.true 'ssl'; then
    ADDON_PROTOCOL=https
fi

#port=$(bashio::addon.port 80)
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s|%%protocol%%|${ADDON_PROTOCOL}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%subpath%%|${FB_BASEURL}/|g" /etc/nginx/servers/ingress.conf
mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

############################
# FILEBROWSER CONFIGURATION #
############################

CONFIG_PATH="/config/filebrowser_quantum.yaml"
mkdir -p /config /cache

export FILEBROWSER_CONFIG="${CONFIG_PATH}"

python3 - <<'PY'
import json
import os

options_path = "/data/options.json"
config_path = os.environ["FILEBROWSER_CONFIG"]

with open(options_path, "r", encoding="utf-8") as f:
    options = json.load(f)

base_url = options.get("base_url") or os.environ.get("FB_BASEURL") or "/"

def bool_or_none(value):
    return value if isinstance(value, bool) else None

sources = []
for source in options.get("sources") or [{"path": "/", "name": "Root", "default_enabled": True}]:
    entry = {"path": source.get("path", "/")}
    if source.get("name"):
        entry["name"] = source["name"]

    source_config = {}
    config_mappings = {
        "default_enabled": "defaultEnabled",
        "default_user_scope": "defaultUserScope",
        "create_user_dir": "createUserDir",
        "disable_indexing": "disableIndexing",
        "deny_by_default": "denyByDefault",
        "private": "private",
        "indexing_interval_minutes": "indexingIntervalMinutes",
    }
    for option_key, config_key in config_mappings.items():
        if option_key in source and source[option_key] not in (None, ""):
            value = source[option_key]
            if option_key == "indexing_interval_minutes" and not value:
                continue
            source_config[config_key] = value

    conditionals = {}
    if "ignore_hidden" in source:
        value = bool_or_none(source.get("ignore_hidden"))
        if value is not None:
            conditionals["ignoreHidden"] = value
    if "ignore_zero_size_folders" in source:
        value = bool_or_none(source.get("ignore_zero_size_folders"))
        if value is not None:
            conditionals["ignoreZeroSizeFolders"] = value
    if conditionals:
        source_config["conditionals"] = conditionals

    if source_config:
        entry["config"] = source_config
    sources.append(entry)

server = {
    "port": 8080,
    "listen": "0.0.0.0",
    "baseURL": base_url,
    "logging": [
        {
            "levels": options.get("log_levels", "info|warning|error"),
        }
    ],
    "database": "/config/filebrowser_quantum.db",
    "cacheDir": "/cache",
    "cacheDirCleanup": options.get("cache_dir_cleanup", True),
    "disablePreviews": options.get("disable_previews", False),
    "disablePreviewResize": options.get("disable_preview_resize", False),
    "disableTypeDetectionByHeader": options.get("disable_type_detection_by_header", False),
    "disableUpdateCheck": options.get("disable_update_check", False),
    "sources": sources,
}

if options.get("external_url"):
    server["externalUrl"] = options["external_url"]
if options.get("internal_url"):
    server["internalUrl"] = options["internal_url"]
if options.get("max_archive_size_gb"):
    server["maxArchiveSize"] = options["max_archive_size_gb"]

certfile = os.environ.get("CERTFILE")
keyfile = os.environ.get("KEYFILE")
if certfile and keyfile:
    server["tlsCert"] = certfile
    server["tlsKey"] = keyfile

auth_method = options.get("auth_method", "password")

password_config = {
    "enabled": auth_method == "password",
    "minLength": options.get("password_min_length", 5),
    "signup": options.get("password_signup", False),
    "enforcedOtp": options.get("password_enforced_otp", False),
}

proxy_config = {
    "enabled": auth_method == "proxy",
}
if options.get("proxy_auth_header"):
    proxy_config["header"] = options["proxy_auth_header"]
proxy_config["createUser"] = options.get("proxy_auth_create_user", False)
if options.get("proxy_auth_logout_redirect_url"):
    proxy_config["logoutRedirectUrl"] = options["proxy_auth_logout_redirect_url"]

oidc_config = {
    "enabled": auth_method == "oidc",
}
if options.get("oidc_client_id"):
    oidc_config["clientId"] = options["oidc_client_id"]
if options.get("oidc_client_secret"):
    oidc_config["clientSecret"] = options["oidc_client_secret"]
if options.get("oidc_issuer_url"):
    oidc_config["issuerUrl"] = options["oidc_issuer_url"]
if options.get("oidc_scopes"):
    oidc_config["scopes"] = options["oidc_scopes"]
if options.get("oidc_user_identifier"):
    oidc_config["userIdentifier"] = options["oidc_user_identifier"]
if options.get("oidc_admin_group"):
    oidc_config["adminGroup"] = options["oidc_admin_group"]
if options.get("oidc_groups_claim"):
    oidc_config["groupsClaim"] = options["oidc_groups_claim"]
if options.get("oidc_logout_redirect_url"):
    oidc_config["logoutRedirectUrl"] = options["oidc_logout_redirect_url"]
oidc_config["createUser"] = options.get("oidc_create_user", False)
oidc_config["disableVerifyTLS"] = options.get("oidc_disable_verify_tls", False)

auth = {
    "tokenExpirationHours": options.get("token_expiration_hours", 2),
    "adminUsername": options.get("admin_username", "admin"),
    "adminPassword": options.get("admin_password", "admin"),
    "methods": {
        "noauth": auth_method == "noauth",
        "password": password_config,
        "proxy": proxy_config,
        "oidc": oidc_config,
    },
}

frontend = {
    "name": "FileBrowser Quantum",
}

config = {
    "server": server,
    "auth": auth,
    "frontend": frontend,
}

with open(config_path, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
PY

######################
# LAUNCH FILEBROWSER #
######################

# Prevent conflicts
for folders in /etc/services.d /etc/s6-overlay; do
    [[ -d "$folders" ]] && rm -r "$folders"
done

bashio::log.info "Starting..."

cd /home/filebrowser
./filebrowser &
bashio::net.wait_for 8080 localhost 900 || true
bashio::log.info "Started !"
nginx || bashio::log.fatal "Nginx failed"
