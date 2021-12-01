ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# copy local files
COPY root/ /

ARG BASHIO_VERSION=0.14.3
RUN \
    ################
    # Install apps #
    ################
    apt-get clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    jq \
    yq \
    cifs-utils \
    keyutils \
    samba \
    smbclient \
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
    #############################
    # Allow UID and GID setting #
    #############################
    \
    && sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser \
    && sed -i "s|chown abc:abc /config||g" /etc/cont-init.d/10-adduser \
    \
    ######################
    # CORRECT PLEX CLAIM #
    ######################
    \
    && sed -i 's/with-contenv bash/with-contenv bashio/g' /etc/cont-init.d/45-plex-claim \
    && sed -i '2iexport PLEX_CLAIM=$(bashio::config "claim")' /etc/cont-init.d/45-plex-claim \
    && sed -i '3i[ $PLEX_CLAIM = "Get_from_https://www.plex.tv/claim" ] && bashio::log.warning "Please change the PLEX_CLAIM code from the options" && exit 1 || true' /etc/cont-init.d/45-plex-claim
###########
# FOLDERS #
########### 
#    && files=$(grep -rl '/config' /etc/cont-init.d/*) && echo $files | xargs sed -i 's|/config|/data|g' \
#    && sed -i "s|/config|/data|g" /defaults/plexmediaserver \
#    && sed -i '2i cp -vnpr /config /data || true' /etc/cont-init.d/00-banner.sh

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
