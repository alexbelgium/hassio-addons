ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:4.0.0
###############################################################################
# Get prebuild containers from Bitwarden RS
###############################################################################
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="1.23.0"

# hadolint ignore=DL3006
FROM "vaultwarden/server:${BUILD_UPSTREAM}" as vaultwarden

###############################################################################
# Build the actual add-on.
###############################################################################
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Get the Bitwarden from official images
COPY --from=vaultwarden /vaultwarden /opt/vaultwarden
COPY --from=vaultwarden /Rocket.toml /opt/Rocket.toml
COPY --from=vaultwarden /web-vault /opt/web-vault

################
# Install apps #
################
# Add rootfs
COPY rootfs/ / 

# Manual apps
ENV PACKAGES="libmariadb-dev-compat \
        libpq5 \
        nginx \
        sqlite3"

# Automatic apps & bashio
RUN $(curl --help &>/dev/null) || (apt-get install -y --no-install-recommends curl || apk add --no-cache curl) && \
    curl -L -f -s "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/zzz_templates/automatic_packages.sh" --output /automatic_packages.sh && \
    chmod 777 /automatic_packages.sh && \
    /automatic_packages.sh && \
    rm /automatic_packages.sh

# Entrypoint logic
#RUN chmod 777 /entrypoint.sh
#WORKDIR /
#ENTRYPOINT [ "/usr/bin/env" ]
#CMD [ "/entrypoint.sh" ] 

### LABELS
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
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
