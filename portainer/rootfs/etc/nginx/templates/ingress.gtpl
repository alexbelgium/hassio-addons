server {
  listen {{ .interface }}:{{ .port }} default_server;
  include /etc/nginx/includes/server_params.conf;
  include /etc/nginx/includes/proxy_params.conf;
  client_max_body_size 0;
  
  location / {
    proxy_pass {{ .protocol }}://backend/;
    resolver 127.0.0.11 valid=30s;
    proxy_set_header Connection "";
  }
  
  location /api/websocket/ {
    proxy_pass {{ .protocol }}://backend/api/websocket/;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    resolver 127.0.0.11 valid=30s;
  }
}
