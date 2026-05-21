# ==============================================================
# Home Assistant Add-on: Aurral
# Wraps the upstream ghcr.io/lklynet/aurral image.
# ==============================================================
ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
    io.hass.name="Aurral" \
    io.hass.description="Self-hosted music discovery and request management for Lidarr" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="petruknw"

ENV AURRAL_DATA_DIR=/config/data \
    DOWNLOAD_FOLDER=/share/aurral/downloads \
    WEEKLY_FLOW_FOLDER=/share/aurral/downloads/weekly-flow

# Pre-create the image-proxy directory at build time and give ownership to
# the node user that the upstream image runs the process as.
RUN mkdir -p /app/backend/data/image-proxy \
 && chown -R node:node /app/backend/data

COPY rootfs /

RUN chmod a+x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "server.js"]
