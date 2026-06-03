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

mkdir -p /config /cache

# Copy default config if not existing
if [ ! -f "$FILEBROWSER_CONFIG" ]; then
    cp /home/filebrowser/data/config.yaml "$FILEBROWSER_CONFIG"
fi

# Update existing fields in config using yq
bashio::log.info "Updating FileBrowser config..."

# --- Server ---
BASE_URL=$(bashio::config 'base_url' "${FB_BASEURL:-/}")
yq e -i ".server.baseURL = \"${BASE_URL}\"" "$FILEBROWSER_CONFIG"

if bashio::config.has_value 'log_levels'; then
    yq e -i ".server.logging[0].levels = \"$(bashio::config 'log_levels')\"" "$FILEBROWSER_CONFIG"
fi

yq e -i ".server.cacheDirCleanup = $(bashio::config 'cache_dir_cleanup' 'true')" "$FILEBROWSER_CONFIG"
yq e -i ".server.disablePreviews = $(bashio::config 'disable_previews' 'false')" "$FILEBROWSER_CONFIG"
yq e -i ".server.disablePreviewResize = $(bashio::config 'disable_preview_resize' 'false')" "$FILEBROWSER_CONFIG"
yq e -i ".server.disableTypeDetectionByHeader = $(bashio::config 'disable_type_detection_by_header' 'false')" "$FILEBROWSER_CONFIG"
yq e -i ".server.disableUpdateCheck = $(bashio::config 'disable_update_check' 'false')" "$FILEBROWSER_CONFIG"

if bashio::config.has_value 'external_url'; then
    yq e -i ".server.externalUrl = \"$(bashio::config 'external_url')\"" "$FILEBROWSER_CONFIG"
fi
if bashio::config.has_value 'internal_url'; then
    yq e -i ".server.internalUrl = \"$(bashio::config 'internal_url')\"" "$FILEBROWSER_CONFIG"
fi
if bashio::config.has_value 'max_archive_size_gb'; then
    yq e -i ".server.maxArchiveSize = $(bashio::config 'max_archive_size_gb')" "$FILEBROWSER_CONFIG"
fi

# SSL cert/key (only when SSL is enabled)
if [ -n "$CERTFILE" ] && [ -n "$KEYFILE" ]; then
    yq e -i ".server.tlsCert = \"${CERTFILE}\"" "$FILEBROWSER_CONFIG"
    yq e -i ".server.tlsKey = \"${KEYFILE}\"" "$FILEBROWSER_CONFIG"
fi

# --- Auth ---
AUTH_METHOD=$(bashio::config 'auth_method' 'password')

yq e -i ".auth.tokenExpirationHours = $(bashio::config 'token_expiration_hours' '2')" "$FILEBROWSER_CONFIG"
yq e -i ".auth.adminUsername = \"$(bashio::config 'admin_username' 'admin')\"" "$FILEBROWSER_CONFIG"
yq e -i ".auth.adminPassword = \"$(bashio::config 'admin_password' 'admin')\"" "$FILEBROWSER_CONFIG"

# Enable/disable auth methods based on auth_method selection
yq e -i ".auth.methods.noauth = $( [ "$AUTH_METHOD" = "noauth" ]    && echo 'true' || echo 'false' )" "$FILEBROWSER_CONFIG"
yq e -i ".auth.methods.password.enabled = $( [ "$AUTH_METHOD" = "password" ] && echo 'true' || echo 'false' )" "$FILEBROWSER_CONFIG"
yq e -i ".auth.methods.proxy.enabled = $( [ "$AUTH_METHOD" = "proxy" ]    && echo 'true' || echo 'false' )" "$FILEBROWSER_CONFIG"
yq e -i ".auth.methods.oidc.enabled = $( [ "$AUTH_METHOD" = "oidc" ]     && echo 'true' || echo 'false' )" "$FILEBROWSER_CONFIG"

# Password settings
if bashio::config.has_value 'password_min_length'; then
    yq e -i ".auth.methods.password.minLength = $(bashio::config 'password_min_length')" "$FILEBROWSER_CONFIG"
fi
yq e -i ".auth.methods.password.signup = $(bashio::config 'password_signup' 'false')" "$FILEBROWSER_CONFIG"
yq e -i ".auth.methods.password.enforcedOtp = $(bashio::config 'password_enforced_otp' 'false')" "$FILEBROWSER_CONFIG"

# Proxy auth settings
if bashio::config.has_value 'proxy_auth_header'; then
    yq e -i ".auth.methods.proxy.header = \"$(bashio::config 'proxy_auth_header')\"" "$FILEBROWSER_CONFIG"
fi
yq e -i ".auth.methods.proxy.createUser = $(bashio::config 'proxy_auth_create_user' 'false')" "$FILEBROWSER_CONFIG"
if bashio::config.has_value 'proxy_auth_logout_redirect_url'; then
    yq e -i ".auth.methods.proxy.logoutRedirectUrl = \"$(bashio::config 'proxy_auth_logout_redirect_url')\"" "$FILEBROWSER_CONFIG"
fi

# OIDC settings
if bashio::config.has_value 'oidc_client_id'; then
    yq e -i ".auth.methods.oidc.clientId = \"$(bashio::config 'oidc_client_id')\"" "$FILEBROWSER_CONFIG"
fi
if bashio::config.has_value 'oidc_client_secret'; then
    yq e -i ".auth.methods.oidc.clientSecret = \"$(bashio::config 'oidc_client_secret')\"" "$FILEBROWSER_CONFIG"
fi
if bashio::config.has_value 'oidc_issuer_url'; then
    yq e -i ".auth.methods.oidc.issuerUrl = \"$(bashio::config 'oidc_issuer_url')\"" "$FILEBROWSER_CONFIG"
fi
if bashio::config.has_value 'oidc_scopes'; then
    yq e -i ".auth.methods.oidc.scopes = \"$(bashio::config 'oidc_scopes')\"" "$FILEBROWSER_CONFIG"
fi
if bashio::config.has_value 'oidc_user_identifier'; then
    yq e -i ".auth.methods.oidc.userIdentifier = \"$(bashio::config 'oidc_user_identifier')\"" "$FILEBROWSER_CONFIG"
fi
if bashio::config.has_value 'oidc_admin_group'; then
    yq e -i ".auth.methods.oidc.adminGroup = \"$(bashio::config 'oidc_admin_group')\"" "$FILEBROWSER_CONFIG"
fi
if bashio::config.has_value 'oidc_groups_claim'; then
    yq e -i ".auth.methods.oidc.groupsClaim = \"$(bashio::config 'oidc_groups_claim')\"" "$FILEBROWSER_CONFIG"
fi
if bashio::config.has_value 'oidc_logout_redirect_url'; then
    yq e -i ".auth.methods.oidc.logoutRedirectUrl = \"$(bashio::config 'oidc_logout_redirect_url')\"" "$FILEBROWSER_CONFIG"
fi
yq e -i ".auth.methods.oidc.createUser = $(bashio::config 'oidc_create_user' 'false')" "$FILEBROWSER_CONFIG"
yq e -i ".auth.methods.oidc.disableVerifyTLS = $(bashio::config 'oidc_disable_verify_tls' 'false')" "$FILEBROWSER_CONFIG"

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
