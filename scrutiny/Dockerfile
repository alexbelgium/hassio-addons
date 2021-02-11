ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}${BUILD_VERSION}

RUN \
    # Allow UID and GID setting
    sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser

# Copy root filesystem
COPY rootfs /

VOLUME [ "/data" ]