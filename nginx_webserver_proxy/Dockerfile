ARG BUILD_FROM=jc21/nginx-proxy-manager:latest
FROM ${BUILD_FROM}

# NPM is Debian-based; install jq for options parsing + stub with-contenv if absent
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/* \
    && if ! command -v with-contenv >/dev/null 2>&1; then \
         printf '#!/usr/bin/env bash\nexec "$@"\n' > /usr/bin/with-contenv \
         && chmod +x /usr/bin/with-contenv; \
       fi

COPY run.sh /npm-addon-init.sh
RUN chmod +x /npm-addon-init.sh

ARG BUILD_VERSION
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="aarch64|amd64"

ENTRYPOINT ["/npm-addon-init.sh"]
