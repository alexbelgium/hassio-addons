#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

NGINX_CONFIG=/etc/nginx/sites-available/ingress.conf
SUBFOLDER="$(bashio::addon.ingress_entry)"
INGRESS_PORT="$(bashio::addon.ingress_port)"
DOWNLOADS_PATH="${HOME:-/config}"

# Home Assistant normally strips the ingress prefix before forwarding to the add-on,
# but keep the normalized value available for diagnostics and future-safe logging.
if [[ -n "${SUBFOLDER}" && "${SUBFOLDER}" != "/" ]]; then
    [[ "${SUBFOLDER}" == */ ]] || SUBFOLDER="${SUBFOLDER}/"
else
    SUBFOLDER="/"
fi

# Claude Desktop exposes only 3001/tcp in config.yaml. Older Supervisor/bashio
# combinations can return an empty ingress_port when it is not explicit, which would
# make nginx write an invalid `listen` directive. Fall back to the declared port.
if [[ -z "${INGRESS_PORT}" ]]; then
    INGRESS_PORT="3001"
fi

DOWNLOADS_PATH="${DOWNLOADS_PATH%/}"

cat > "${NGINX_CONFIG}" <<EOF
server {
  listen ${INGRESS_PORT} default_server;
  client_max_body_size 10M;

  location / {
    alias /usr/share/selkies/web/;
    index index.html index.htm;
    try_files \$uri \$uri/ /index.html;
  }

  location /devmode {
    proxy_set_header        Upgrade \$http_upgrade;
    proxy_set_header        Connection "upgrade";
    proxy_set_header        Host \$host;
    proxy_set_header        X-Real-IP \$remote_addr;
    proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto \$scheme;
    proxy_http_version      1.1;
    proxy_read_timeout      3600s;
    proxy_send_timeout      3600s;
    proxy_connect_timeout   3600s;
    proxy_buffering         off;
    proxy_set_header        Accept-Encoding "";
    proxy_pass              http://127.0.0.1:5173;
  }

  # Current Selkies WebSocket mode connects to <base>/api/websockets.
  # The older linuxserver default.conf only proxies /websocket, leaving the
  # dashboard loaded but stuck on "waiting for stream" under Home Assistant ingress.
  location /api/ {
    proxy_set_header        Upgrade \$http_upgrade;
    proxy_set_header        Connection "upgrade";
    proxy_set_header        Host \$host;
    proxy_set_header        X-Real-IP \$remote_addr;
    proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto \$scheme;
    proxy_http_version      1.1;
    proxy_read_timeout      3600s;
    proxy_send_timeout      3600s;
    proxy_connect_timeout   3600s;
    proxy_buffering         off;
    proxy_set_header        Accept-Encoding "";
    proxy_pass              http://127.0.0.1:8082;
  }

  # Keep compatibility with older Selkies/noVNC clients and linuxserver templates.
  location /websocket {
    proxy_set_header        Upgrade \$http_upgrade;
    proxy_set_header        Connection "upgrade";
    proxy_set_header        Host \$host;
    proxy_set_header        X-Real-IP \$remote_addr;
    proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto \$scheme;
    proxy_http_version      1.1;
    proxy_read_timeout      3600s;
    proxy_send_timeout      3600s;
    proxy_connect_timeout   3600s;
    proxy_buffering         off;
    proxy_set_header        Accept-Encoding "";
    proxy_pass              http://127.0.0.1:8082;
  }

  location /files {
    fancyindex on;
    fancyindex_footer /nginx/footer.html;
    fancyindex_header /nginx/header.html;
    alias ${DOWNLOADS_PATH}/;
    if (-f \$request_filename) {
      add_header Content-Disposition "attachment";
      add_header X-Content-Type-Options "nosniff";
    }
  }

  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root /usr/share/selkies/web/;
  }
}
EOF

cp "${NGINX_CONFIG}" /etc/nginx/sites-enabled
