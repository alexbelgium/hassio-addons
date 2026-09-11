server {
  listen {{ .interface }}:{{ .port }} default_server;
  listen {{ .interface }}:9099 default_server;
  include /etc/nginx/includes/server_params.conf;
  include /etc/nginx/includes/proxy_params.conf;
  client_max_body_size 0;
  gzip off;

  proxy_hide_header X-Frame-Options;
  proxy_hide_header Content-Security-Policy;
  add_header X-Frame-Options "SAMEORIGIN";
  add_header Content-Security-Policy "frame-ancestors *";

  location / {
    proxy_pass {{ .protocol }}://backend/;
    resolver 127.0.0.11 valid=180s;

    # These headers must be under location section, if they moved into proxy_params.conf, even if this is valid, they won't work
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Host $http_host;

    # Portainer gzips its own responses, which makes them chunked with no
    # Content-Length. Home Assistant's ingress relay only buffers responses
    # under 4 MB that carry a Content-Length, so everything else falls into
    # its streaming path. Asking upstream for identity keeps the small
    # responses buffered. The map in nginx.conf applies this to the ingress
    # listener only, so direct access on 9099 keeps compression.
    proxy_set_header Accept-Encoding $upstream_accept_encoding;
  }
}
