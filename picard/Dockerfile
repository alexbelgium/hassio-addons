ARG BUILD_FROM=hassioaddons/base:8.0.1
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Setup base
RUN apk add --no-cache \
    picard

# Build arugments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="Picard" \
    io.hass.description="Texte" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium" \