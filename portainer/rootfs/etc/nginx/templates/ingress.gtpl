server {
  listen {{ .interface }}:{{ .port }} default_server;
  include /etc/nginx/includes/server_params.conf;
  include /etc/nginx/includes/proxy_params.conf;
      
  location / {
    proxy_pass {{ .protocol }}://backend;
  }

}
