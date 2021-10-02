ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="22.2.0"

FROM ${BUILD_FROM}

ENV NEXTCLOUD_PATH="/data/config/www/nextcloud"

# Added repo to solve issues with some systems that cause error code 1 when fetching apk
# Add bashio
RUN \
    #Avoid issues with sources 
    echo 'https://dl-3.alpinelinux.org/alpine/latest-stable/main' > /etc/apk/repositories \ 
    && echo '@testing https://dl-3.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \ 
    && echo '@community https://dl-3.alpinelinux.org/alpine/latest-stable/community' >> /etc/apk/repositories \
    \
    #Install bashio
    && apk cache clean \
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
    && apk add --no-cache gcompat@community \
    \
    # modify/copy files
    && sed -i "s|data|share/nextcloud|g" /etc/cont-init.d/* \
    && sed -i "s|config|data/config|g" /etc/cont-init.d/* \
    && sed -i "s|data|share/nextcloud|g" /etc/services.d/nginx/* \
    && sed -i "s|config|data/config|g" /etc/services.d/nginx/*

COPY root/ /

RUN ["chmod", "+x", "/defaults/nextcloud-perms.sh"]

VOLUME ["/share", "/ssl", "/data", "/media"]
