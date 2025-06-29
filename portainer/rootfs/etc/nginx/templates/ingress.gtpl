server {
  listen {{ .interface }}:{{ .port }} default_server;
  listen {{ .interface }}:9099 default_server;
  include /etc/nginx/includes/server_params.conf;
  include /etc/nginx/includes/proxy_params.conf;
  client_max_body_size 0;

  location / {
    proxy_pass {{ .protocol }}://backend/;
    resolver 127.0.0.11 valid=180s;

    # These headers must be under location section, if they moved into proxy_params.conf, even if this is valid, they won't work
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Host $http_host;
  }
}
