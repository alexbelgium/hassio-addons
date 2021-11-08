ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="22.2.0"

FROM ${BUILD_FROM}

ENV NEXTCLOUD_PATH="/data/config/www/nextcloud"
ARG BUILD_ARCH
ARG BASHIO_VERSION=0.13.1

COPY root/ /

# Add bashio
RUN \
    echo "Install version $BUILD_VERSION on $BUILD_ARCH" \
    ##################
    # Install bashio #
    ##################
    && echo "**** Install Bashio ****" \
    && apk add --no-cache \
    curl jq wget \
    && curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
    /tmp/bashio.tar.gz \
    --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr /tmp/bashio.tar.gz \
    \
    #gclib compatibility 
    && apk add --no-cache gcompat@community || true

RUN \
    # modify/copy files
    sed -i "s|data|share/nextcloud|g" /etc/cont-init.d/* \
    && sed -i "s|config|data/config|g" /etc/cont-init.d/* \
    && sed -i "s|data|share/nextcloud|g" /etc/services.d/nginx/* \
    && sed -i "s|config|data/config|g" /etc/services.d/nginx/*

RUN ["chmod", "+x", "/defaults/nextcloud-perms.sh"]

VOLUME ["/share", "/ssl", "/data", "/media"]

### LABELS
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/alexbelgium" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
