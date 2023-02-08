server {
  listen {{ .interface }}:{{ .port }} default_server;
  server_name vue.torrent;
  include /etc/nginx/includes/server_params.conf;
  include /etc/nginx/includes/proxy_params.conf;

  location / {
    root /vuetorrent/public/;
    # avoid cache
    expires -1;               # kill cache
    proxy_no_cache 1;         # don't cache it
    proxy_cache_bypass 1;     # even if cached, don't try to use it
  }

  location /api {
    proxy_pass {{ .protocol }}://backend;
    http2_push_preload on;
    client_max_body_size 10M;
  }

}
