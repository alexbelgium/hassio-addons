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
# 1 Base Image  #
#################
ARG BUILD_VERSION
FROM ghcr.io/ente-io/server:latest

#########################
# 2 S6 / base settings  #
#########################
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
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
# 4 Core packages + Postgres 17 server & client (apk)  #
########################################################
# NOTE: Ente base image is Alpine; use apk. We install bash for bashio scripts.
# Try to pull PG17 from edge; if unavailable fall back to distro default (may be lower major).
RUN set -eux; \
  apk update; \
  apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
      bash curl ca-certificates wget jq sudo tzdata \
      postgresql17 postgresql17-client || \
  (echo "edge PG17 not available, falling back to distro postgresql"; \
   apk add --no-cache postgresql postgresql-client bash curl ca-certificates wget jq sudo tzdata); \
  # create /bin/bash symlink for scripts that expect it
  ln -sf /usr/bin/bash /bin/bash

###################################
# 5 MinIO server + CLI (per‑arch) #
###################################
# Detect arch at build time using Alpine uname.
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
# 6 Ensure predictable paths for museum & ente‑web  #
#####################################################
RUN set -eux; \
    MUSEUM_PATH="$(command -v museum || true)"; \
    if [ -n "$MUSEUM_PATH" ]; then ln -sf "$MUSEUM_PATH" /usr/bin/museum; fi; \
    WEB_PATH="$(command -v ente-web || true)"; \
    if [ -n "$WEB_PATH" ]; then ln -sf "$WEB_PATH" /usr/bin/ente-web; fi

##################
# 7 Install apps #
##################
# Optional modules (same pattern as your other add‑ons)
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
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint_modif.sh" "/ha_entrypoint_modif.sh"
RUN chmod 777 /ha_entrypoint.sh /ha_entrypoint_modif.sh \
 && /ha_entrypoint_modif.sh && rm /ha_entrypoint_modif.sh

############################
# 9 Copy add‑on rootfs tree #
############################
# (bashio‑aware cont‑init.d + services.d scripts)
COPY rootfs/ /

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
# S6 supervises internal services; no CMD override.
