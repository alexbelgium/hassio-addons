ARG BUILD_VERSION
FROM nathanvaughn/webtrees:latest

ARG BASHIO_VERSION=0.13.1

# Copy root filesystem
COPY rootfs /

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
    # Use data from addon options for all values
    && sed -i 's|cat \"\$|jq ."|g' /docker-entrypoint.sh \
    && sed -i 's|_FILE" 2> /dev/null| //empty" /data/options.json|g' /docker-entrypoint.sh \
    # Remove last line and add copy script
    && chmod a+x /run.sh \
    && sed -i "2 i\./start.sh" /docker-entrypoint.sh \
    && sed -i '$ d' /docker-entrypoint.sh \
    && sed -i '$ i\./end.sh' /docker-entrypoint.sh
    
#    
# Add initial script


#VOLUME [ "/data" ]
#USER root
# Base system
#ARG BUILD_ARCH
#RUN chmod a+x /docker-entrypoint.sh
    ################
    # Modify image #
    ################
    #chmod a+x /run.sh \
    #&& sed -i "2 i\./run.sh || true" /docker-entrypoint.sh \
    #&& cp -n /var/www/webtrees /data \
    #&& grep -rlZ 'foo' . | xargs -0 sed -i.bak 's|/var/www/webtrees|/data|g'
    #&& sed -i 's!/bin/bash/bashio/g' /docker-entrypoint.sh
    # Add script
    #&& sed -i '1d' /docker-entrypoint.sh \
   # && cat /newscript > /temporaryfile \
    #&& cat /docker-entrypoint.sh >> /temporaryfile \
   # && cat /temporaryfile > /docker-entrypoint.sh \
   # && chmod +x /docker-entrypoint.sh \
 #   && rm /temporaryfile
    # Add correct location
    #&& sed -i "s|CONFIG_FILE="data|CONFIG_FILE="/data|g" /etc/cont-init.d/
    ################
    # Modify image #
    ################
    # && cp -n /defaults/config.ini.php /data \
    #&& ln -s /data/config.ini.php /var/www/webtrees/data \
    #&& touch /data/webtrees.sqlite \
    #&& ln -s /data/webtrees.sqlite /var/www/webtrees/data
#ENV WEBTREES_HOME="/data"
#WORKDIR $WEBTREES_HOME
#ENTRYPOINT ["/run.sh"]
#COPY /var/www/webtrees/.htaccess $WEBTREES_HOME 
#RUN rm - $WEBTREES_HOMER /var/www/webtrees/data \
#   && ln -s /data /var/www/webtrees
#RUN touch /data/database.sqlite \
#    && ln -s /data/database.sqlite /var/www/webtrees/data \
#    && touch /data/config.ini.php \
#   && ln -s /data/config.ini.php /var/www/webtrees/data

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
