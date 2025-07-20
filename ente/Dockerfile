#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#           _.------.
#       _.-`    ('>.-`"""-.
# '.--'`       _'`   _ .--.)
#    -'         '-.-';`   `
#    ' -      _.'  ``'--.
#      d  '---`    .-'""`
#               /`
#=== Home Assistant Add‑on – ENTE (server + web UI) ===#

########################################################
# 0 ▸ Build the ente‑web static front‑end (multi‑stage) #
########################################################
FROM node:22-alpine AS web-builder

# All web sources must live in ./ente-web relative to this Dockerfile
WORKDIR /src
COPY ente-web/ .

# Use placeholders; they get patched at container start‑up
ENV NEXT_PUBLIC_ENTE_ENDPOINT=ENTE_API_ORIGIN_PLACEHOLDER \
    NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=ENTE_ALBUMS_ORIGIN_PLACEHOLDER

# GitHub ARM runners sometimes time‑out ⇒ raise network limit
RUN yarn config set network-timeout 900000 -g \
 && yarn install --frozen-lockfile \
 && yarn build:photos \
 && yarn build:accounts \
 && yarn build:auth \
 && yarn build:cast


#################
# 1 ▸ Base image #
#################
ARG BUILD_VERSION
FROM ghcr.io/ente-io/server:latest

##################
# 2 ▸ Tune image #
##################
# ----- S6 flags -----
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0
USER root

# ----- LSIO helper -----
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_lsio.sh" /ha_lsio.sh
ARG CONFIGLOCATION="/config"
RUN chmod 744 /ha_lsio.sh && \
    if grep -qr "lsio" /etc; then /ha_lsio.sh "$CONFIGLOCATION"; fi && \
    rm /ha_lsio.sh

# ----- MinIO, Postgres client & friends -----
RUN set -eux; \
    apk add --no-cache \
        bash curl ca-certificates wget jq tini postgresql15-client; \
    curl -fsSL https://dl.min.io/server/minio/release/linux-amd64/minio -o /usr/local/bin/minio; \
    curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc; \
    chmod +x /usr/local/bin/minio /usr/local/bin/mc
RUN apk add --no-cache \
        lsb-release curl gnupg wget tini jq sudo \
        postgresql postgresql-client

# ----- ente‑web static bundle -----
RUN apk add --no-cache nginx

# › Static files
COPY --from=web-builder /src/apps/photos/out    /www/photos
COPY --from=web-builder /src/apps/accounts/out  /www/accounts
COPY --from=web-builder /src/apps/auth/out      /www/auth
COPY --from=web-builder /src/apps/cast/out      /www/cast

# › Nginx conf expected by /etc/cont-init.d/run.sh
RUN mkdir -p /etc/ente-web
COPY <<'EOF' /etc/ente-web/nginx.conf
worker_processes 1;
events { worker_connections 1024; }

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile      on;
    keepalive_timeout 65;

    server {
        listen 3000;
        root /www/photos;
        location / { try_files $uri $uri.html /index.html; }
    }
    server {
        listen 3001;
        root /www/accounts;
        location / { try_files $uri $uri.html /index.html; }
    }
    server {
        listen 3002;
        root /www/photos;
        location / { try_files $uri $uri.html /index.html; }
    }
    server {
        listen 3003;
        root /www/auth;
        location / { try_files $uri $uri.html /index.html; }
    }
    server {
        listen 3004;
        root /www/cast;
        location / { try_files $uri $uri.html /index.html; }
    }
}
EOF

# › Runtime placeholder replacement
COPY <<'EOF' /usr/local/bin/ente-web-prepare
#!/usr/bin/env ash
set -eu
: "${ENTE_API_ORIGIN:=http://localhost:8080}"
: "${ENTE_ALBUMS_ORIGIN:=${ENTE_API_ORIGIN}}"

echo "[ente-web-prepare] Patching bundles:"
echo "  ENTE_API_ORIGIN      = $ENTE_API_ORIGIN"
echo "  ENTE_ALBUMS_ORIGIN   = $ENTE_ALBUMS_ORIGIN"

find /www -name '*.js'      | xargs sed -i "s#ENTE_API_ORIGIN_PLACEHOLDER#${ENTE_API_ORIGIN}#g"
find /www/photos -name '*.js' | xargs sed -i "s#ENTE_ALBUMS_ORIGIN_PLACEHOLDER#${ENTE_ALBUMS_ORIGIN}#g"
EOF
RUN chmod +x /usr/local/bin/ente-web-prepare


##################
# 3 ▸ Add-ons, etc. #
##################
COPY rootfs/ /

# Optional modules
ARG MODULES="00-banner.sh 01-custom_script.sh 00-global_var.sh 00-local_mounts.sh 00-smb_mounts.sh"
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" /ha_automodules.sh
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Optional extra packages
ENV PACKAGES="sudo jq yamllint"
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" /ha_autoapps.sh
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh


################
# 4 ▸ Entrypoint #
################
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh"        /ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint_modif.sh"  /ha_entrypoint_modif.sh
RUN chmod 777 /ha_entrypoint.sh /ha_entrypoint_modif.sh && \
    /ha_entrypoint_modif.sh && rm /ha_entrypoint_modif.sh

ENTRYPOINT ["/usr/bin/env"]
CMD        ["/ha_entrypoint.sh"]

############
# 5 ▸ Labels #
############
ARG BUILD_ARCH BUILD_DATE BUILD_NAME BUILD_DESCRIPTION BUILD_REF BUILD_REPOSITORY
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.url="https://github.com/alexbelgium" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

#################
# 6 ▸ Finish line #
#################
# S6 will detect scripts in /etc/services.d (copied via rootfs)
# and launch   → minio   → museum API   → nginx (ente‑web)

# Expose the SPA ports so HA can map them
EXPOSE 3000 3001 3002 3003 3004
