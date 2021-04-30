ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="2.0.1"

FROM ${BUILD_FROM}${BUILD_UPSTREAM}

# Add bashio
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
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
    && rm -fr /tmp/bashio.tar.gz

# Copy root filesystem
COPY rootfs / 

RUN \
    # Allow UID and GID setting
    sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    # && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    # && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser \
    # Change config path
    && sed -i "s| /config| /data/config|g" /etc/cont-init.d/* \
    && sed -i "s| /config| /data/config|g" /defaults/*

VOLUME [ "/data" ] 
