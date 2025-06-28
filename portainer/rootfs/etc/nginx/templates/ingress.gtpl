server {
  listen {{ .interface }}:{{ .port }} default_server;
  listen {{ .interface }}:9099 default_server;
  include /etc/nginx/includes/server_params.conf;
  include /etc/nginx/includes/proxy_params.conf;
  client_max_body_size 0;

  location / {
    proxy_pass {{ .protocol }}://backend/;
    resolver 127.0.0.11 valid=180s;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Host $http_host;
  }

  location /api/websocket/ {
    proxy_pass {{ .protocol }}://backend/api/websocket/;
    resolver 127.0.0.11 valid=180s;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Host $http_host;
  }
}
