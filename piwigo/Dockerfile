ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}

# Copy root filesystem
COPY rootfs / 

VOLUME [ "/data" ]

RUN \
    # Install bashio
    apk add --no-cache \
    jq \
    curl \
    cifs-utils \
    \
    && curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v0.13.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
    /tmp/bashio.tar.gz \
    --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr \
    /tmp/* \
    \
    # Allow UID and GID setting
    && sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser \
    # Use subfolder in config
    && files=$(grep -rl "/config" /defaults/*) && echo $files | xargs sed -i "s|/config|/config/piwigo|g" \
    && files=$(grep -rl "/config" /etc/cont-init.d/*) && echo $files | xargs sed -i "s|/config|/config/piwigo|g" \
    && files=$(grep -rl "/gallery/include/config/piwigo/piwigo_default.inc.php" /etc/cont-init.d/*) && echo $files | xargs sed -i "s|/gallery/include/config/piwigo/piwigo_default.inc.php|/gallery/include/config_default.inc.php|g" \
    && files=$(grep -rl "/config" /etc/services.d/*) && echo $files | xargs sed -i "s|/config|/config/piwigo|g" 


