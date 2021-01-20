ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:4.0.0
###############################################################################
# Get prebuild containers from Bitwarden RS
###############################################################################
ARG BUILD_VERSION

# hadolint ignore=DL3006
FROM "bitwardenrs/server:${BUILD_VERSION}" as bitwarden

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
        nginx=1.14.2-2+deb10u3 \
    && apt-get clean \
    && rm -f -r \
        /etc/nginx \
    \
    && mkdir -p /var/log/nginx \
    && touch /var/log/nginx/error.log

# Copy root filesystem
COPY rootfs /
