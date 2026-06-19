ARG BUILD_FROM=jc21/nginx-proxy-manager:latest
FROM ${BUILD_FROM}

# NPM is Debian-based; install jq for options parsing and ensure bash is present.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /npm-addon-init.sh
RUN chmod 0755 /npm-addon-init.sh

ARG BUILD_VERSION
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="aarch64|amd64"

ENTRYPOINT ["/bin/bash", "/npm-addon-init.sh"]
