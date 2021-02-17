ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}${BUILD_VERSION}

# Copy root filesystem
COPY rootfs / 

RUN \
    # Install bashio
    apt-get update \
    \
    && apt-get install -y --no-install-recommends \
    jq \
    wget \
    \
    && apt-get -y upgrade cifs-utils \
    && curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v0.7.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
    /tmp/bashio.tar.gz \
    --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr \
    /tmp/* \
    /var/{cache,log}/* \
    /var/lib/apt/lists/* \
    \
    # Allow UID and GID setting
    && sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser \
    # Correct permissions 
    && sed -i 's=	/config=/config/qBittorrent /config/data/qBittorrent || true=g' /etc/cont-init.d/30-config \
    # Set download folder to /share
    && sed -i 's|/downloads/|/share/qBittorrent/|g' /defaults/qBittorrent.conf \
    # Remove fixed folders, allows connection to webUI
    && sed '11,13d' /defaults/qBittorrent.conf \ 
    && echo 'WebUI\HostHeaderValidation=false' >> /defaults/qBittorrent.conf \
    && echo 'WebUI\LocalHostAuth=false' >> /defaults/qBittorrent.conf

VOLUME [ "/data" ]
