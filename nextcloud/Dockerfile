ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="20.0.7"

FROM ${BUILD_FROM}${BUILD_UPSTREAM}

ENV NEXTCLOUD_PATH="/data/config/www/nextcloud"

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Added repo to solve issues with some systems that cause error code 1 when fetching apk
# Add bashio
RUN echo 'https://dl-3.alpinelinux.org/alpine/latest-stable/main' > /etc/apk/repositories \ 
    && echo '@testing https://dl-3.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \ 
    && echo '@community https://dl-3.alpinelinux.org/alpine/latest-stable/community' >> /etc/apk/repositories \
    \
    && apk add --no-cache \
    curl jq \
    && curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v0.10.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
    /tmp/bashio.tar.gz \
    --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr /tmp/bashio.tar.gz

# modify/copy files
RUN sed -i "s|data|share/nextcloud|g" /etc/cont-init.d/*

RUN sed -i "s|config|data/config|g" /etc/cont-init.d/*

RUN sed -i "s|data|share/nextcloud|g" /etc/services.d/nginx/*

RUN sed -i "s|config|data/config|g" /etc/services.d/nginx/*

COPY root/ /

# modify/copy files
#RUN sed -i "s|data|share/nextcloud|g" /etc/cont-init.d/* \
#    && sed -i "s|config|data/config|g" /etc/cont-init.d/* \
#    && sed -i "s|data|share/nextcloud|g" /etc/services.d/nginx/* \
#    && sed -i "s|config|data/config|g" /etc/services.d/nginx/* \
    # Allow UID and GID setting
run sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
   && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
   && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser

RUN ["chmod", "+x", "/defaults/nextcloud-perms.sh"]

VOLUME ["/share", "/ssl", "/data", "/media"]
