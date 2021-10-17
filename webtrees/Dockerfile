ARG BUILD_VERSION
FROM nathanvaughn/webtrees:latest

VOLUME [ "/data" ]

USER root

#RUN rm -R /var/www/webtrees/data \
#   && ln -s /data /var/www/webtrees

RUN touch /data/database.sqlite \
   # && chown webtrees /data/database.sqlite \
    && ln -s /data/database.sqlite /var/www/webtrees/data

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
