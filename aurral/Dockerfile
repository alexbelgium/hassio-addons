# ==============================================================
# Home Assistant Add-on: Aurral
# Wraps the upstream ghcr.io/lklynet/aurral image.
# ==============================================================
FROM ghcr.io/lklynet/aurral:1.76.17

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

COPY rootfs /

RUN chmod a+x /etc/services.d/aurral/run \
    && mkdir -p /config/data
