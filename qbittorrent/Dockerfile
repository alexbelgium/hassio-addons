ARG BUILD_FROM
ARG BUILD_VERSION 
ARG BUILD_UPSTREAM="14.3.6.99202106272003-7387-ac8105c30ubuntu20.04.1-ls141"
FROM ${BUILD_FROM}${BUILD_UPSTREAM}

# Base system
ARG BASHIO_VERSION=0.13.0
ARG TEMPIO_VERSION=2021.01.0
ARG BUILD_ARCH

RUN \
    ####################
    # AVOID NTP ISSUES #
    ####################
    yum install -y ntp && \
    service ntpd stop && \
    ntpdate pool.ntp.org && \
    \    
    ################
    # Install apps #
    ################
    apt-get update && \
    apt-get install -y \
        apt-transport-https \
        jq \
        curl \
        cifs-utils \
        keyutils \
        nginx \
        coreutils \
        openvpn \
    \    
    ##################
    # Install tempio #
    ##################
    curl -L -f -s -o /usr/bin/tempio \
    "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}" && \
    chmod a+x /usr/bin/tempio && \
    \
    ##############
    # STATISTICS #
    ##############
    curl -L -f -s -o /tmp/tmp \
    "https://github.com/alexbelgium/downloads-tracker/archive/refs/tags/Qbittorrent.zip" && \
    \
    ##################
    # Install bashio #
    ##################
    mkdir -p /tmp/bashio && \
    curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" && \
    | tar -xzf - --strip 1 -C /tmp/bashio && \
    mv /tmp/bashio/lib /usr/lib/bashio && \
    ln -s /usr/lib/bashio/bashio /usr/bin/bashio && \
    rm -rf /tmp/bashio && \
    \
    ########################################
    # Correct upstream image folders links #
    ########################################
    \
    # Allow UID and GID setting
    sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser && \
    sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser && \
    sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser && \
    \
    # Correct permissions 
    sed -i 's|/config|-R /config/qBittorrent|g' /etc/cont-init.d/10-adduser && \
    sed -i 's=	/config=/config/qBittorrent || true=g' /etc/cont-init.d/30-config && \
    \
    # Set download folder to /share
    sed -i 's|/downloads/|/share/qBittorrent/|g' /defaults/qBittorrent.conf && \
    \
    # Remove fixed folders, allows connection to webUI
    sed '11,13d' /defaults/qBittorrent.conf && \
    echo 'WebUI\HostHeaderValidation=false' >> /defaults/qBittorrent.conf && \
    echo 'WebUI\LocalHostAuth=false' >> /defaults/qBittorrent.conf

# Copy root filesystem
COPY rootfs / 

VOLUME [ "/data" ]

### LABELS
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/alexbelgium" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
