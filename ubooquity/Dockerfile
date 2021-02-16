ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}${BUILD_VERSION}

# Copy root filesystem
COPY rootfs / 

# Add bashio
RUN apk add --no-cache \
    curl \
    jq \
    && curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v0.7.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
    /tmp/bashio.tar.gz \
    --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr /tmp/bashio.tar.gz \
    \
    # Allow UID and GID setting
    && sed -i 's|bash|bashio|g' /etc/cont-init.d/10-adduser \
    && sed -i 's|{PUID:-911}|(bashio::config "PUID")|g' /etc/cont-init.d/10-adduser \
    && sed -i 's|{PGID:-911}|(bashio::config "PGID")|g' /etc/cont-init.d/10-adduser \
    # Set config directory
    && sed -i 's|/config|/config/ubooquity|g' /etc/cont-init.d/30-config \
    && sed -i 's|/config|/config/ubooquity|g' /etc/services.d/ubooquity/run \
    # Allow maximum memory setting
    && sed -i 's|bash|bashio|g' /etc/services.d/ubooquity/run \
    && sed -i 's|{MAXMEM:-512}|(bashio::config "maxmem")|g' /etc/services.d/ubooquity/run

VOLUME [ "/data" ]
