server {
  listen {{ .interface }}:{{ .port }} default_server;
  server_name vue.torrent;
  include /etc/nginx/includes/server_params.conf;
  include /etc/nginx/includes/proxy_params.conf;

  location / {
    root /vuetorrent/public/;
  }

  location /api {
    proxy_pass {{ .protocol }}://backend;
    http2_push_preload on;
    client_max_body_size 10M;
  }

}
