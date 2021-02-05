ARG BUILD_FROM
ARG BUILD_VERSION

FROM ${BUILD_FROM}${BUILD_VERSION}

# Install bashio
RUN apt-get update \
    \
    && apt-get install -y --no-install-recommends \
    jq \
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
# Remove fixed folders, allows connection to webUI
    && sed '11,13d' /defaults/qBittorrent.conf \ 
# Allow connection to webUI
    && echo 'WebUI\HostHeaderValidation=false' >> /defaults/qBittorrent.conf \
    && echo 'WebUI\LocalHostAuth=false' >> /defaults/qBittorrent.conf \
    && echo 'WebUI\Username=Homeassistant' >> /defaults/qBittorrent.conf
      
# Copy root filesystem
COPY rootfs /

VOLUME [ "/data" "/config" ]
