ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="22.2.0"

FROM ${BUILD_FROM}

ENV NEXTCLOUD_PATH="/data/config/www/nextcloud"
ARG BUILD_ARCH

# Add bashio
RUN \
    echo "Install version $BUILD_VERSION on $BUILD_ARCH" \
    #Install bashio
    && echo "**** Install Bashio ****" \
    && apk add --no-cache \
    curl jq \
    && curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v0.13.1.tar.gz" \
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

COPY root/ /

RUN ["chmod", "+x", "/defaults/nextcloud-perms.sh"]

VOLUME ["/share", "/ssl", "/data", "/media"]
