#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Disables ingress and sets a default index

# Disable Ingress
if bashio::config.true "ingress_disabled"; then
    bashio::log.warning "Ingress is disabled. You'll need to connect using ip:port"

    # Adapt ingress.conf
    sed -i "/root/d" /etc/nginx/servers/ingress.conf
    sed -i "/proxy_pass/i root /etc;" /etc/nginx/servers/ingress.conf
    sed -i "/proxy_pass/i try_files '' /ingress.html =404;" /etc/nginx/servers/ingress.conf
    sed -i "/proxy_pass/d" /etc/nginx/servers/ingress.conf

    # Create index.html
    touch /etc/ingress.html
    cat > /etc/ingress.html << EOF
<!DOCTYPE html>
<html>
  <head>
    <title>Ingress is disabled!</title>
  </head>
  <body>
    <div class="your_class"></div>
    <p style="background-color:black;color:yellow">
      Ingress was disabled by the user. Please connect using ip:port or
      re-enable in the addons options.
    </p>
  </body>
</html>

EOF
fi
