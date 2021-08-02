ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}
ARG BASHIO_VERSION=0.13.1

RUN \
    ################
    # Install apps #
    ################
    apk add --no-cache \
      curl \
      jq \
    \
    ###################
    # Install bashio #
    ##################
    && mkdir -p /tmp/bashio \
    && curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    | tar -xzf - --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio \
    \
    ########################################
    # Correct upstream image folders links #
    ########################################
    \
    # Allow UID and GID setting
    && sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser \
    \
    # Allow custom config folder
    && grep -rl '/config' /defaults/ | xargs sed -i 's|/config|/data/organizr|g' \
    && grep -rl '/config' /etc/cont-init.d/ | xargs sed -i 's|/config|/data/organizr|g' \
    && grep -rl '/config' /etc/logrotate.d/ | xargs sed -i 's|/config|/data/organizr|g' \
    && grep -rl '/config' /etc/services.d/ | xargs sed -i 's|/config|/data/organizr|g'

# copy local files
COPY root/ /
