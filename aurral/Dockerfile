# ==============================================================
# Home Assistant Add-on: Aurral
# Wraps the upstream ghcr.io/lklynet/aurral image.
# ==============================================================
FROM ghcr.io/lklynet/aurral:latest

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
    io.hass.name="Aurral" \
    io.hass.description="Self-hosted music discovery and request management for Lidarr" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="petruknw"

# Set data dir via Docker ENV so it's available before any shell script runs.
# /config is HA's addon_config mount point (always writable).
ENV AURRAL_DATA_DIR=/config/data

COPY rootfs /

RUN chmod a+x /etc/services.d/aurral/run \
    && chmod a+x /usr/local/bin/docker-entrypoint.sh \
    # Pre-create the data dir so the entrypoint chown succeeds at startup
    && mkdir -p /config/data
