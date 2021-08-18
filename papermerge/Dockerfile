ARG BUILD_FROM
ARG BUILD_VERSION

FROM ${BUILD_FROM}

# Add bashio
ARG BASHIO_VERSION=0.13.1 
RUN \
    ################
    # Install apps #
    ################
    apt-get update \
    && apt-get install -y --no-install-recommends \
        jq \
        curl \
        cifs-utils \
        keyutils \
        samba \
    \ 
    ###################
    # Install bashio #
    ##################
    && mkdir -p /tmp/bashio \
    && curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    | tar -xzf - --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio || true

# Copy root filesystem
COPY rootfs / 

RUN \
    # Allow UID and GID setting
    sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    # && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    # && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser \
    # Change config path
    && sed -i "s| /config| /data/config|g" /etc/cont-init.d/* \
    && sed -i "s| /config| /data/config|g" /defaults/* || true

VOLUME [ "/data" ] 
