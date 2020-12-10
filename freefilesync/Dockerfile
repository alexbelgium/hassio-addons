ARG BUILD_FROM=hassioaddons/base:latest
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Setup base
RUN mkdir /freefilesync \
	&& curl -J -L -o /tmp/FreeFileSync_11.4_Linux.tar.gz \
        "https://freefilesync.org/download/FreeFileSync_11.4_Linux.tar.gz" \
    && mkdir /freefilesync \
    && tar zxvf \
        /FreeFileSync_11.4_Linux.tar.gz \
        --strip 1 -C /freefilesync
		
RUN sed -i "s|/config|/FreeFileSync|g" /freefilesync/FreeFileSync

# Build arugments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="Transmission" \
    io.hass.description="The torrent client for Hass.io with OpenVPN support" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Pierrick Rouxel <pierrickrouxel@addons.community>" \
    org.label-schema.description="The torrent client for Hass.io" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name="Transmission" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://github.com/pierrickrouxel" \
    org.label-schema.usage="https://github.com/pierrickrouxel/hassio-addon-transmission/tree/master/README.md" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-url="https://github.com/pierrickrouxel" \
    org.label-schema.vendor="Community Hass.io Addons"
