ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}

COPY rootfs / 

ENV BASHIO_VERSION=0.14.3

RUN \
    ################
    # Install apps #
    ################
    apt-get update && apt-get install -y jq curl bash && apt-get clean || apk add --no-cache jq curl bash \
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
    ###############
    # Adapt image #
    ###############
    # Correct data path
    && grep -rl "/app/data" /app | xargs sed -i 's|/app/data|/data|g' \
    # Add custom instructions to run.sh
    && sed -i '1d' /app/mealie/run.sh \ 
    && cat /app/mealie/run.sh >> /run.txt \
    && cat /run.txt > /app/mealie/run.sh \
    && chmod +x /app/mealie/run.sh
# Add custom caddy instructions for ingress
#&& cat /caddy.txt >> /app/Caddyfile

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
