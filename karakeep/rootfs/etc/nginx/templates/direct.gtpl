server {
    {{ if not .ssl }}
    listen {{ .port }} default_server;
    {{ else }}
    listen {{ .port }} default_server ssl;
    {{ end }}

    include /etc/nginx/includes/server_params.conf;
    include /etc/nginx/includes/proxy_params.conf;

    {{ if .ssl }}
    include /etc/nginx/includes/ssl_params.conf;

    ssl_certificate {{ .certfile }};
    ssl_certificate_key {{ .keyfile }};
    {{ end }}

    location / {
        {{ if .ingress_user }}
        set $ingress_user "";

        if ($remote_addr = 172.30.32.2) {
            set $ingress_user {{ .ingress_user }};
        }

        proxy_set_header X-WebAuth-User $ingress_user;
        {{ end }}

        proxy_pass {{ .protocol }}://backend;
    }
}