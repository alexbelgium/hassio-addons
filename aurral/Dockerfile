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

COPY rootfs /

RUN chmod a+x /etc/services.d/aurral/run
