#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: AdGuard Home
# Configures NGINX for use with the AdGuard Home server
# ==============================================================================
declare adguard_port=45158
declare adguard_protocol=http
declare admin_port
declare certfile
declare dns_host
declare ingress_interface
declare ingress_port
declare keyfile
declare tls_port

if bashio::var.true "$(yq read /data/adguard/AdGuardHome.yaml tls.enabled)";
then
    tls_port=$(yq read /data/adguard/AdGuardHome.yaml tls.port_https)
    if bashio::var.has_value "${tls_port}" && [[ "${tls_port}" -ne 0 ]]; then
        adguard_port="${tls_port}"
        adguard_protocol=https
    fi
fi

sed -i "s#%%port%%#${adguard_port}#g" /etc/nginx/includes/upstream.conf
sed -i "s#%%protocol%%#${adguard_protocol}#g" /etc/nginx/servers/ingress.conf

admin_port=$(bashio::addon.port 80)
if bashio::var.has_value "${admin_port}"; then
    bashio::config.require.ssl

    if bashio::config.true 'ssl'; then
        certfile=$(bashio::config 'certfile')
        keyfile=$(bashio::config 'keyfile')

        mv /etc/nginx/servers/direct-ssl.disabled /etc/nginx/servers/direct.conf
        sed -i "s#%%certfile%%#${certfile}#g" /etc/nginx/servers/direct.conf
        sed -i "s#%%keyfile%%#${keyfile}#g" /etc/nginx/servers/direct.conf

    else
        mv /etc/nginx/servers/direct.disabled /etc/nginx/servers/direct.conf
    fi

    sed -i "s/%%port%%/${admin_port}/g" /etc/nginx/servers/direct.conf
    sed -i "s#%%protocol%%#${adguard_protocol}#g" /etc/nginx/servers/direct.conf
fi

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf

dns_host=$(bashio::dns.host)
sed -i "s/%%dns_host%%/${dns_host}/g" /etc/nginx/includes/resolver.conf
