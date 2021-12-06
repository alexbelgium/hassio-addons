FROM troglobit/inadyn:latest

# Base system
ENV BASHIO_VERSION=0.14.3
ARG TEMPIO_VERSION=2021.01.0
ARG BUILD_ARCH

ENV LANG='C.UTF-8'\
    TERM='xterm-256color'\
    GOPATH='/opt/go'

RUN \
    ################
    # Install apps #
    ################
    apk add --no-cache \
    curl \
    jq \
    bash \
    xz build-base libressl-dev ca-certificates npm \
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
    ####################
    # Install mustache #
    ####################
    && apk add --no-cache \
    go \
    npm \
    #    && npm install mustache-cli --global        
    && apk upgrade --no-cache &&\
    apk add --no-cache --virtual .build-deps\
    build-base\
    git\
    go &&\
    go get -u github.com/quantumew/mustache-cli &&\
    cp $GOPATH/bin/* /usr/bin/ && \
    rm -rf $GOPATH /var/cache/apk/* /tmp/src &&\
    apk del .build-deps xz build-base

# Copy root filesystem
COPY rootfs / 

WORKDIR /
RUN chmod 777 /run.sh
ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "/run.sh" ] 
CMD ["/run.sh"]

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
