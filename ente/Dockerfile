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
#=== Home Assistant Add‑on – ENTE ===#
#################
# 1 Build Image #
#################

# Stage 1: Build the web applications
FROM node:22-alpine AS builder
WORKDIR /build
COPY . .
ENV NEXT_PUBLIC_ENTE_ENDPOINT=ENTE_API_ORIGIN_PLACEHOLDER
ENV NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=ENTE_ALBUMS_ORIGIN_PLACEHOLDER
RUN yarn config set network-timeout 900000 -g && \
    yarn install && \
    yarn build:photos && \
    yarn build:accounts && \
    yarn build:auth && \
    yarn build:cast

# Stage 2: Main image
ARG BUILD_VERSION
FROM ghcr.io/ente-io/server:latest
##################
# 2 Modify Image #
##################
# S6 settings
ENV  S6_CMD_WAIT_FOR_SERVICES=1 \
     S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
     S6_SERVICES_GRACETIME=0
USER root
# LSIO helpers (same repo you already use)
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_lsio.sh" "/ha_lsio.sh"
ARG CONFIGLOCATION="/config"
RUN chmod 744 /ha_lsio.sh && \
    if grep -qr "lsio" /etc; then /ha_lsio.sh "$CONFIGLOCATION"; fi && \
    rm /ha_lsio.sh
# ---------- MinIO & tools (needed by Ente) ----------
# – server binary + client (`mc`)
RUN set -eux; \
    apk add --no-cache \
      bash curl ca-certificates wget jq tini postgresql15-client; \
    curl -fsSL https://dl.min.io/server/minio/release/linux-amd64/minio -o /usr/local/bin/minio; \
    curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc; \
    chmod +x /usr/local/bin/minio /usr/local/bin/mc
RUN apk update && \
    apk add --no-cache \
        lsb-release curl gnupg wget tini jq sudo \
        postgresql postgresql-client

# Copy built web applications from the builder stage
COPY --from=builder /build/apps/photos/out /out/photos
COPY --from=builder /build/apps/accounts/out /out/accounts
COPY --from=builder /build/apps/auth/out /out/auth
COPY --from=builder /build/apps/cast/out /out/cast

# Install nginx and configure it
RUN apk add --no-cache nginx && \
    mkdir -p /etc/nginx/conf.d && \
    echo 'server {' > /etc/nginx/conf.d/default.conf && \
    echo '    listen 3000; root /out/photos;' >> /etc/nginx/conf.d/default.conf && \
    echo '    location / { try_files $uri $uri.html /index.html; }' >> /etc/nginx/conf.d/default.conf && \
    echo '}' >> /etc/nginx/conf.d/default.conf && \
    echo 'server {' >> /etc/nginx/conf.d/default.conf && \
    echo '    listen 3001; root /out/accounts;' >> /etc/nginx/conf.d/default.conf && \
    echo '    location / { try_files $uri $uri.html /index.html; }' >> /etc/nginx/conf.d/default.conf && \
    echo '}' >> /etc/nginx/conf.d/default.conf && \
    echo 'server {' >> /etc/nginx/conf.d/default.conf && \
    echo '    listen 3002; root /out/photos;' >> /etc/nginx/conf.d/default.conf && \
    echo '    location / { try_files $uri $uri.html /index.html; }' >> /etc/nginx/conf.d/default.conf && \
    echo '}' >> /etc/nginx/conf.d/default.conf && \
    echo 'server {' >> /etc/nginx/conf.d/default.conf && \
    echo '    listen 3003; root /out/auth;' >> /etc/nginx/conf.d/default.conf && \
    echo '    location / { try_files $uri $uri.html /index.html; }' >> /etc/nginx/conf.d/default.conf && \
    echo '}' >> /etc/nginx/conf.d/default.conf && \
    echo 'server {' >> /etc/nginx/conf.d/default.conf && \
    echo '    listen 3004; root /out/cast;' >> /etc/nginx/conf.d/default.conf && \
    echo '    location / { try_files $uri $uri.html /index.html; }' >> /etc/nginx/conf.d/default.conf && \
    echo '}' >> /etc/nginx/conf.d/default.conf

ENV ENTE_API_ORIGIN=http://localhost:8080
ENV ENTE_ALBUMS_ORIGIN=https://localhost:3002

# Create entrypoint script to replace environment variables
RUN mkdir -p /docker-entrypoint.d && \
    echo '#!/bin/sh' > /docker-entrypoint.d/90-replace-ente-env.sh && \
    echo 'find /out -name '"'"'*.js'"'"' |' >> /docker-entrypoint.d/90-replace-ente-env.sh && \
    echo '    xargs sed -i'"'"''"'"'"' "s#ENTE_API_ORIGIN_PLACEHOLDER#$ENTE_API_ORIGIN#g"' >> /docker-entrypoint.d/90-replace-ente-env.sh && \
    echo 'find /out/photos -name '"'"'*.js'"'"' |' >> /docker-entrypoint.d/90-replace-ente-env.sh && \
    echo '    xargs sed -i'"'"''"'"'"' "s#ENTE_ALBUMS_ORIGIN_PLACEHOLDER#$ENTE_ALBUMS_ORIGIN#g"' >> /docker-entrypoint.d/90-replace-ente-env.sh && \
    chmod +x /docker-entrypoint.d/90-replace-ente-env.sh

# Create S6 service for nginx
RUN mkdir -p /etc/services.d/nginx && \
    echo '#!/bin/sh' > /etc/services.d/nginx/run && \
    echo 'exec nginx -g "daemon off;"' >> /etc/services.d/nginx/run && \
    chmod +x /etc/services.d/nginx/run

# Expose ports for nginx
EXPOSE 3000 3001 3002 3003 3004

##################
# 3 Install apps #
##################
COPY rootfs/ /
# bind‑compat for some addons
#RUN ln -sf /usr/bin/bash /bin/bash || true && \
#    ln -sf /usr/bin/sh   /bin/sh   || true
# Optional modules (same pattern as ente)
ARG MODULES="00-banner.sh 01-custom_script.sh 00-global_var.sh 00-local_mounts.sh 00-smb_mounts.sh"
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" "/ha_automodules.sh"
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh
# Optional extra packages
ENV PACKAGES="sudo jq yamllint"
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" "/ha_autoapps.sh"
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################
ENV  S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint_modif.sh" "/ha_entrypoint_modif.sh"
RUN chmod 777 /ha_entrypoint.sh /ha_entrypoint_modif.sh && \
    /ha_entrypoint_modif.sh && rm /ha_entrypoint_modif.sh
ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "/ha_entrypoint.sh" ]

############
# 5 Labels #
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
# 6 Finish line #
#################
# S6 will pick up run scripts from /etc/services.d supplied in rootfs
# and launch:  › minio  › museum API  › (optional) web‑UI
