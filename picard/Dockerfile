ARG BUILD_FROM=hassioaddons/base:8.0.1
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Copy root filesystem
COPY rootfs /

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
    io.hass.description="Picard is a cross-platform music tagger written in Python." \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium" \
    org.label-schema.description="Picard is a cross-platform music tagger written in Python." \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name="Picard" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://github.com/alexbelgium" \
    org.label-schema.usage="" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-url="https://github.com/alexbelgium" \
    org.label-schema.vendor="Community Hass.io Addons"
