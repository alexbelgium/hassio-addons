ARG BUILD_VERSION
FROM nathanvaughn/webtrees:latest

# Copy root filesystem
COPY rootfs /

# Global variables
ARG BASHIO_VERSION=0.13.1
ENV WEBTREES_HOME="/data/webtrees"
WORKDIR $WEBTREES_HOME
ENTRYPOINT ["/start.sh"]
VOLUME ["/data"]

RUN \
    ################
    # Install apps #
    ################
    apt-get clean \
    && apt-get update \
    && apt-get install -y \
        jq \
        curl \
    && apt-get clean \
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
    ################
    # Modify image #
    ################
    # Change data location
    && cp -rn /var/www/webtrees /data \
    && mkdir -p /data/webtrees \
    && chown -R www-data:www-data /data/webtrees \
    && grep -rl "/var/www/webtrees" /etc/ | xargs sed -i 's|/var/www/webtrees|/data/webtrees|g' \ 
    \
    # Use data from addon options for all values
    #&& sed -i 's|cat \"\$|jq ."|g' /docker-entrypoint.sh \
    #&& sed -i 's|_FILE" 2> /dev/null| //empty" /data/options.json|g' /docker-entrypoint.sh \
    \
    # Add entry script
    && chown root:root /start.sh \
    && chmod a+x /start.sh \
    #&& sed -i "2 i\cd / && ./start.sh" /docker-entrypoint.sh \
    # Add end script
    && chown root:root /end.sh \
    && chmod a+x /end.sh \
    && sed -i '$ d' /docker-entrypoint.sh
    #&& sed -i '$ i\export DB_NAME=$DB_NAME && export WT_USER=$WT_USER && export WT_PASS=$WT_PASS && cd / && ./end.sh' /docker-entrypoint.sh

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
    maintainer="tyjtyj (https://github.com/tyjtyj)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="tyjtyj (https://github.com/tyjtyj)" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/tyjtyj" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
