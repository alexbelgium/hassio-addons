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
    # Remove fixed folders, allows connection to webUI
    && sed '11,13d' /defaults/qBittorrent.conf \ 
    && echo 'WebUI\HostHeaderValidation=false' >> /defaults/qBittorrent.conf \
    && echo 'WebUI\LocalHostAuth=false' >> /defaults/qBittorrent.conf
    # use /data instead of /config for hass.io environment
    # &&  files=$(grep -rls '/config' /) && echo $files | xargs sed -i "s=/config=/data=g" \
    # Allow custom scripts execution
    && chmod -R 755 /scripts/



VOLUME [ "/data" ]
