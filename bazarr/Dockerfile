ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="0.9.6"
FROM ${BUILD_FROM}${BUILD_UPSTREAM}
ARG BASHIO_VERSION=0.13.0

RUN \
    ###############################
    # Install apps test both dist #
    ###############################
    apt-get update \
    && apt-get install -y \
        jq \
        curl \
        cifs-utils \
        keyutils \
    || apk add --no-cache \
        jq \
        curl \
        cifs-utils \
        keyutils \
    \ 
    ##################
    # Install bashio #
    ##################
    && mkdir -p /tmp/bashio \
    && curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    | tar -xzf - --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio \
    \
    # Correct config folder
    && grep -rl " /config" /etc/cont-init.d | xargs sed -i 's| /config| /config/bazarr|g' \
    && grep -rl " /config" /etc/services.d | xargs sed -i 's| /config| /config/bazarr|g' \
    && sed -i 's=/config/flexget=/config/bazarr || true=g' /etc/cont-init.d/10-adduser \
    \
    # Allow UID and GID setting
    && sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser

# copy local files
COPY root/ /
