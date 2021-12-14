#################
# 1 Build Image #
#################

ARG BUILD_UPSTREAM="7.14.2"
FROM elasticsearch:$BUILD_UPSTREAM

##################
# 2 Modify Image #
##################

# Data persistence
RUN sed -i '5a echo "Data location moved. Please wait while elasticsearch starts..."' /usr/local/bin/docker-entrypoint.sh \
    && sed -i '5a chown -R $(id -u):$(id -g) $HOME' /usr/local/bin/docker-entrypoint.sh \
    && sed -i '5a done' /usr/local/bin/docker-entrypoint.sh \
    && sed -i '5a ln -s $NEWHOME/$files /usr/share/elasticsearch || true' /usr/local/bin/docker-entrypoint.sh \
    && sed -i '5a rm -r /usr/share/elasticsearch/$files || true' /usr/local/bin/docker-entrypoint.sh \
    && sed -i '5a cp -rn /usr/share/elasticsearch/$files $NEWHOME || true' /usr/local/bin/docker-entrypoint.sh \
    && sed -i '5a for files in "data" "config"; do' /usr/local/bin/docker-entrypoint.sh \
    && sed -i '5a mkdir -p $NEWHOME' /usr/local/bin/docker-entrypoint.sh \
    && sed -i '5a NEWHOME="/data"' /usr/local/bin/docker-entrypoint.sh \
    # Install plugins     
    && /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch ingest-attachment

##################
# 3 Install apps #
##################

################
# 4 Entrypoint #
################

############
# 5 Labels #
############

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
