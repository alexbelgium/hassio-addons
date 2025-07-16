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

# Put museum / web on a predictable path for your run-scripts
RUN ln -sf $(command -v museum)    /usr/bin/museum     && \
    ln -sf $(command -v ente-web)  /usr/bin/ente-web

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

# ---------- Healthcheck ----------
#ENV HEALTH_PORT="8080" \
#    HEALTH_URL="/ping"
#HEALTHCHECK --interval=10s --retries=5 --timeout=20s CMD \
#    curl -A "HealthCheck: Docker/1.0" -fs "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" || exit 1

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
