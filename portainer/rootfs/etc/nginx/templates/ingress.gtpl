server {
  listen {{ .interface }}:{{ .port }} default_server;
  listen {{ .interface }}:9099 default_server;
  include /etc/nginx/includes/server_params.conf;
  include /etc/nginx/includes/proxy_params.conf;
  client_max_body_size 0;

  location / {
    proxy_pass {{ .protocol }}://backend/;
    resolver 127.0.0.11 valid=180s;
    proxy_set_header Connection "";
    proxy_connect_timeout 30m;
    proxy_send_timeout 30m;
    proxy_read_timeout 30m;
    proxy_set_header Origin "";
    # Ensure the backend knows the correct host
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Host $http_host;
}

  location /api/websocket/ {
    proxy_pass {{ .protocol }}://backend/api/websocket/;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Origin "";
    resolver 127.0.0.11 valid=180s;
    proxy_connect_timeout 30m;
    proxy_send_timeout 30m;
    proxy_read_timeout 30m;
    # Ensure the backend knows the correct host
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Host $http_host;
  }
}

