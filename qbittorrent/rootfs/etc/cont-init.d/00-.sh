#!/bin/bash

if [ ! -f "/usr/bin/bashio" ]; then
    echo "Bashio does not exist, executing script"

    ################
    # Install apps #
    ################
    apt-get clean \
    && apt-get update \
    && apt-get install -y \
    jq \
    curl \
    cifs-utils \
    keyutils \
    samba \
    smbclient \
    nginx \
    coreutils \
    openvpn \
    && apt-get clean
    
    ##################
    # Install tempio #
    ##################
    curl -L -f -s -o /usr/bin/tempio \
    "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/tempio

    ##################
    # Install bashio #
    ##################
    mkdir -p /tmp/bashio \
    && curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    | tar -xzf - --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio \

    ########################################
    # Correct upstream image folders links #
    ########################################
    # Allow UID and GID setting
    sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser \
    \
    # Correct permissions 
    && sed -i 's=/config=/config/qBittorrent || true=g' /etc/cont-init.d/10-adduser \    
    && sed -i 's=	/config=/config/qBittorrent || true=g' /etc/cont-init.d/30-config \
    \
    # Set download folder to /share
    && sed -i 's|/downloads/|/share/qBittorrent/|g' /defaults/qBittorrent.conf \
    \
    # Remove fixed folders, allows connection to webUI
    && sed '11,13d' /defaults/qBittorrent.conf \ 
    && echo 'WebUI\HostHeaderValidation=false' >> /defaults/qBittorrent.conf \
    && echo 'WebUI\LocalHostAuth=false' >> /defaults/qBittorrent.conf

fi
