#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#           _.------.
#       _.-`    ('>.-`"""-.
# '.--'`       _'`   _ .--.)
#    -'         '-.-';`   `
#    ' -      _.'  ``'--.
#        '---`    .-'""`
#               /`
#=== Home Assistant Addon ===#

#################
# 1 Build Image #
#################

ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="0.34.0"
FROM ghcr.io/frankieramirez/comicarr:${BUILD_UPSTREAM}

##################
# 2 Modify Image #
##################

USER root

# No S6_* tuning here : the upstream image is a plain python:3.12-slim with no
# s6-overlay, so the vars the other addons set would be read by nobody

##################
# 3 Install apps #
##################

# Add rootfs
# Absolute paths on purpose : the upstream image sets WORKDIR /opt/comicarr, so
# the relative "find ." used by the other addons would miss /etc entirely
COPY rootfs/ /
RUN find /etc/cont-init.d /etc/services.d -type f \( -name "*.sh" -o -name "run" \) -print -exec chmod +x {} \;

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES="00-banner.sh 00-global_var.sh 01-custom_script.sh 00-local_mounts.sh 00-smb_mounts.sh"

# Automatic modules download
# Runs before the apps installer on purpose (the repo-wide order) : this script
# bootstraps bash, curl and ca-certificates itself, which the slim base lacks,
# and the apps installer below decides what to install by grepping the modules
# it downloads here
COPY ha_automodules.sh /ha_automodules.sh
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="nginx"

# Automatic apps & bashio
COPY ha_autoapps.sh /ha_autoapps.sh
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# The upstream image ships no s6-overlay, so ha_entrypoint runs as pid 1 : it
# executes /etc/cont-init.d, then supervises /etc/services.d. This replaces the
# upstream /entrypoint.sh, which services.d/comicarr/run still calls when the
# user asks for an unprivileged uid.
COPY ha_entrypoint.sh /ha_entrypoint.sh
RUN chmod 0755 /ha_entrypoint.sh
ENTRYPOINT ["/ha_entrypoint.sh"]

# Install bashio
COPY bashio-standalone.sh /usr/local/lib/bashio-standalone.sh
RUN chmod 0755 /usr/local/lib/bashio-standalone.sh

############
# 5 Labels #
############

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
ENV BUILD_VERSION="${BUILD_VERSION}"
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/alexbelgium" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

#################
# 6 Healthcheck #
#################

# First boot runs the alembic migrations against a cold sqlite database, which
# is slow on a low-end arm board : leave it time to settle before failing
ENV HEALTH_PORT="8090" \
    HEALTH_URL="/api/health"
HEALTHCHECK \
    --interval=30s \
    --retries=5 \
    --start-period=180s \
    --timeout=25s \
    CMD curl -A "HealthCheck: Docker/1.0" -s -f "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" >/dev/null 2>&1 || exit 1
