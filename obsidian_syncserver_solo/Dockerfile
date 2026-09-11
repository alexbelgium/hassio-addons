ARG BUILD_FROM=couchdb:3.5.2
FROM ${BUILD_FROM}

# The official couchdb image is Debian-based and carries no s6-overlay, so
# this add-on runs run.sh directly rather than through the s6 service tree
# the other add-ons in this repository use.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        openssl \
        ripgrep \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

ARG BUILD_VERSION
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="aarch64|amd64"

ENTRYPOINT ["/run.sh"]
