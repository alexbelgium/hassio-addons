server {
  listen %%interface%%:8096 ssl;
  server_name emby;
  include /etc/nginx/includes/server_params.conf;
  include /etc/nginx/includes/proxy_params.conf;
  include /etc/nginx/includes/ssl_params.conf;
  ssl_certificate %%certfile%%;
  ssl_certificate_key %%certkey%%;

location ^~ / {
    include /config/nginx/proxy.conf;
    include /config/nginx/resolver.conf;
    proxy_pass http://backend;
}

location ^~ /embywebsocket {
    include /config/nginx/proxy.conf;
    include /config/nginx/resolver.conf;
    proxy_pass http://backend;
}


}
