# check=skip=SecretsUsedInArgOrEnv
ARG BUILD_FROM=ghcr.io/karakeep-app/karakeep:0.30.0

ARG MEILI_VERSION="v1.13.3"

FROM getmeili/meilisearch:${MEILI_VERSION} AS meilisearch

FROM ${BUILD_FROM}

# Environment variables
ENV \
    DATA_DIR="/share/karakeep" \
    MEILI_DIR="/config/meili" \
    DISABLE_NEW_RELEASE_CHECK=true \
    BROWSER_WEB_URL="http://127.0.0.1:9222" \
    MEILI_ADDR="http://127.0.0.1:7700" \
    MEILI_MASTER_KEY="0uIHQXWthY2L2yqCWGVGu2axN+l4qcDEc+Of/7e8X7bEyZ8k" \
    MEILI_NO_ANALYTICS=true \
    XDG_CACHE_HOME="/data/cache"

ENV \
    CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/ \
    CHROMIUM_FLAGS="--disable-software-rasterizer --disable-dev-shm-usage" \
    MEILI_HTTP_ADDR=0.0.0.0:7700 \
    MEILI_SERVER_PROVIDER=docker \
    MEILI_ENV=production

ENV \
    SERVICE_PORT=3000 \
    NGINX_PORT=8080

# NGINX Install
RUN \
    apk add --no-cache \
        bash \
        openssl \
        nginx \
    && rm -rf /etc/nginx

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Addon base configuration
ARG BUILD_ARCH=amd64
# renovate: datasource=github-releases packageName=hassio-addons/bashio
ARG BASHIO_VERSION="v0.17.5"
# renovate: datasource=github-releases packageName=home-assistant/tempio
ARG TEMPIO_VERSION="2024.11.2"
RUN \
    set -o pipefail \
    && apk add --no-cache --virtual .build-dependencies \
        tar \
        xz \
    && apk add --no-cache \
        libcrypto3 \
        libssl3 \
        musl-utils \
        musl \
        curl \
        jq \
        tzdata \
    \
    && curl -J -L "https://github.com/hassio-addons/bashio/archive/${BASHIO_VERSION}.tar.gz" -o /tmp/bashio.tar.gz \
    && mkdir /tmp/bashio \
    && tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    \
    && curl -L -s "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}" -o /usr/bin/tempio \
    && chmod a+x /usr/bin/tempio \
    \
    && apk del --no-cache --purge .build-dependencies \
    && rm -rf /tmp/*

# Installs latest Chromium package.
RUN \
    apk upgrade --no-cache --available \
    && apk add --no-cache \
      chromium \
      chromium-swiftshader \
      ttf-freefont \
      font-noto-emoji \
      font-wqy-zenhei \
    && mkdir -p /usr/src/chrome \
    && adduser -D chrome \
    && chown -R chrome:chrome /usr/src/chrome

COPY --from=meilisearch /bin/meilisearch /bin/meilitool /bin/

COPY .common/addon-config /
COPY .common/nginx /

COPY rootfs/ /

ARG BUILD_VERSION \
    BUILD_DATE \
    BUILD_DESCRIPTION \
    BUILD_NAME \
    BUILD_REF \
    BUILD_REPOSITORY

LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="Fabio Garavini <info@fabiogaravini.dev>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Fabio Garavini Hassio Add-ons" \
    org.opencontainers.image.authors="Fabio Garavini <info@fabiogaravini.dev>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/fabio-garavini" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
