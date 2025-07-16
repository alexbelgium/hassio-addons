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

############################
# Stage 0: pull web assets #
############################
FROM ghcr.io/ente-io/web:latest AS enteweb
# This image already contains the built static outputs for photos/accounts/auth/cast
# under /out plus a default nginx conf. We’ll copy those into the final image. 

#################
# 1 Base Image  #
#################
ARG BUILD_VERSION
FROM ghcr.io/ente-io/server:latest

#########################
# 2 S6 / base settings  #
#########################
ENV  S6_CMD_WAIT_FOR_SERVICES=1 \
     S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
     S6_SERVICES_GRACETIME=0

USER root

#############################################
# 3 LSIO helper patch (same pattern as you) #
#############################################
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_lsio.sh" "/ha_lsio.sh"
ARG CONFIGLOCATION="/config"
RUN chmod 744 /ha_lsio.sh \
 && if grep -qr "lsio" /etc; then /ha_lsio.sh "$CONFIGLOCATION"; fi \
 && rm /ha_lsio.sh

########################################################
# 4 Core packages + Postgres server/client + nginx etc #
########################################################
RUN set -eux \
 && apk update \
 && apk add --no-cache \
      bash curl ca-certificates wget jq sudo tzdata tini \
      postgresql postgresql-client \
      nginx \
 && ln -sf /usr/bin/bash /bin/bash

###################################
# 5 MinIO server + CLI (per‑arch) #
###################################
ARG TARGETARCH
RUN set -eux; \
    arch="${TARGETARCH:-$(uname -m)}"; \
    case "$arch" in \
      amd64|x86_64) minio_arch="amd64" ;; \
      arm64|aarch64) minio_arch="arm64" ;; \
      *) minio_arch="amd64" ;; \
    esac; \
    curl -fsSL "https://dl.min.io/server/minio/release/linux-${minio_arch}/minio" -o /usr/local/bin/minio; \
    curl -fsSL "https://dl.min.io/client/mc/release/linux-${minio_arch}/mc" -o /usr/local/bin/mc; \
    chmod +x /usr/local/bin/minio /usr/local/bin/mc

#####################################################
# 6 Copy Ente web static assets from enteweb stage  #
#####################################################
# Static output (architecture‑independent)
COPY --from=enteweb /out/ /opt/ente-web/out/
# We’ll supply our own nginx conf tuned for HA add‑on ports.
COPY <<'EOF' /etc/ente-web/nginx.conf
# Minimal nginx master config that includes our vhosts.
worker_processes auto;
pid /run/nginx.pid;
events { worker_connections 1024; }

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    sendfile on;
    keepalive_timeout 65;

    # gzip etc. optional
    server_tokens off;

    # Photos (main UI) - port 3000
    server {
        listen 3000;
        root /opt/ente-web/out/photos;
        index index.html;
        location / {
            try_files $uri $uri/ /index.html;
        }
    }

    # Accounts - port 3001
    server {
        listen 3001;
        root /opt/ente-web/out/accounts;
        index index.html;
        location / {
            try_files $uri $uri/ /index.html;
        }
    }

    # Public albums - port 3002
    server {
        listen 3002;
        root /opt/ente-web/out/photos;
        index index.html;
        location / {
            try_files $uri $uri/ /index.html;
        }
    }

    # Auth - port 3003
    server {
        listen 3003;
        root /opt/ente-web/out/auth;
        index index.html;
        location / {
            try_files $uri $uri/ /index.html;
        }
    }

    # Cast - port 3004
    server {
        listen 3004;
        root /opt/ente-web/out/cast;
        index index.html;
        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
EOF

# Runtime env replacement script (mirrors official ente web Dockerfile behaviour)
COPY <<'EOF' /usr/local/bin/ente-web-prepare
#!/usr/bin/env sh
set -eu

API_ORIGIN="${ENTE_API_ORIGIN:-http://localhost:8080}"
ALBUMS_ORIGIN="${ENTE_ALBUMS_ORIGIN:-http://localhost:3002}"

# Replace placeholders in built JS bundles
# These placeholders exist in official Ente web builds. 
find /opt/ente-web/out -type f -name '*.js' -print0 \
  | xargs -0 sed -i "s#ENTE_API_ORIGIN_PLACEHOLDER#${API_ORIGIN}#g"

# Albums origin applies only to photos app
if [ -d /opt/ente-web/out/photos ]; then
  find /opt/ente-web/out/photos -type f -name '*.js' -print0 \
    | xargs -0 sed -i "s#ENTE_ALBUMS_ORIGIN_PLACEHOLDER#${ALBUMS_ORIGIN}#g"
fi

exit 0
EOF
RUN chmod +x /usr/local/bin/ente-web-prepare

#####################################################
# 7 Optional modules (same pattern as your add‑ons) #
#####################################################
ARG MODULES="00-banner.sh 01-custom_script.sh 00-global_var.sh 00-local_mounts.sh 00-smb_mounts.sh"
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" "/ha_automodules.sh"
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Optional extra packages via your helper
ENV PACKAGES="sudo jq yamllint"
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" "/ha_autoapps.sh"
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 8 Entrypoint #
################
ENV  S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint_modif.sh" "/ha_entrypoint_modif.sh"
RUN chmod 777 /ha_entrypoint.sh /ha_entrypoint_modif.sh \
 && /ha_entrypoint_modif.sh && rm /ha_entrypoint_modif.sh

############################
# 9 Copy add‑on rootfs tree #
############################
COPY rootfs/ /

ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "/ha_entrypoint.sh" ]

##########################################
# 10 Healthcheck (museum exposes /ping)  #
##########################################
ENV HEALTH_PORT="8080" \
    HEALTH_URL="/ping"
HEALTHCHECK --interval=10s --retries=5 --timeout=20s CMD \
    curl -A "HealthCheck: Docker/1.0" -fs "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" || exit 1

############
# 11 Labels #
############
ARG BUILD_ARCH BUILD_DATE BUILD_NAME BUILD_DESCRIPTION BUILD_REF BUILD_REPOSITORY
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.url="https://github.com/alexbelgium" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${BUILD_REF}" \
    org.opencontainers.image.version="${BUILD_VERSION}"

#################
# 12 Finish line#
#################
# Startup orchestrated by /etc/cont-init.d/99-run.sh (museum, Postgres, MinIO, nginx web).
