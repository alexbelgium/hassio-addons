ARG BUILD_FROM=hassioaddons/debian-base:3.2.1
###############################################################################
# Get prebuild containers from Bitwarden RS
###############################################################################
ARG BITWARDEN_ARCH
# hadolint ignore=DL3006
FROM "bitwardenrs/server:1.18.0${BITWARDEN_ARCH}" as bitwarden

###############################################################################
# Build the actual add-on.
###############################################################################
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Get the Bitwarden from official images
COPY --from=bitwarden /bitwarden_rs /opt/bitwarden_rs
COPY --from=bitwarden /Rocket.toml /opt/Rocket.toml
COPY --from=bitwarden /web-vault /opt/web-vault

# add Nginx
# hadolint ignore=DL3009
RUN \
    apt-get update \
    \
    && apt-get install -y --no-install-recommends \
        nginx=1.14.2-2+deb10u3 libpq5 libmariadb3 \
    && apt-get clean \
    && rm -f -r \
        /etc/nginx \
    \
    && mkdir -p /var/log/nginx \
    && touch /var/log/nginx/error.log

# Copy root filesystem
COPY rootfs /

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="Bitwarden RS" \
    io.hass.description="Open source password management solution" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.title="Bitwarden RS" \
    org.opencontainers.image.description="Open source password management solution" \
    org.opencontainers.image.vendor="Home Assistant Community Add-ons" \
    org.opencontainers.image.authors="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://addons.community" \
    org.opencontainers.image.source="https://github.com/hassio-addons/addon-bitwarden" \
    org.opencontainers.image.documentation="https://github.com/hassio-addons/addon-bitwarden/blob/master/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
