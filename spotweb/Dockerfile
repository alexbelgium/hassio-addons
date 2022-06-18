#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#           _.------.
#       _.-`    ('>.-`"""-.
# '.--'`       _'`   _ .--.)
#    -'         '-.-';`   `
#    ' -      _.'  ``'--.
#        '---`    .-'""`
#               /`
#=== Home Assistant Addon ===#

#################
# 1 Build Image #
#################

ARG BUILD_FROM=ghcr.io/hassio-addons/base/amd64:11.0.0
# hadolint ignore=DL3006
FROM $BUILD_FROM

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=300000 \
    S6_SERVICES_GRACETIME=300000

ENV LANG C.UTF-8

# Environment variables
ENV APP_ID="spotweb"
ENV APP_NAME="Spotweb"
ENV APP_DIR="/app"
ENV BUILD_UPSTREAM="1.5.1"

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base
# hadolint ignore=DL3003
# Install app dependencies
RUN apk -U update && \
    # hadolint ignore=DL3017
    apk -U upgrade && \
    apk -U add --no-cache \
    git \
    nginx \
    php8 \
    php8-fpm \
    php8-curl \
    php8-dom \
    php8-gettext \
    php8-xml \
    php8-simplexml \
    php8-zip \
    php8-zlib \
    php8-gd \
    php8-openssl \
    php8-mysqli \
    php8-pdo \
    php8-pdo_mysql \
    php8-pgsql \
    php8-pdo_pgsql \
    php8-sqlite3 \
    php8-pdo_sqlite \
    php8-json \
    php8-mbstring \
    php8-ctype \
    php8-opcache \
    php8-session \
    mariadb-client \
    \
    && mkdir -p /app \
    # Install latest Spotweb release
    && git clone --depth=1 https://github.com/spotweb/spotweb.git /app \
    # spotweb needs a timezone set in the php.ini
    # TODO: Can we dynamically set the correct timezone here ?
    && sed -i "s/;date.timezone =/date.timezone = \"Europe\/Amsterdam\"/g" /etc/php8/php.ini \
    && mkdir /app/cache \
    && mkdir /var/tmp/nginx

##################
# 3 Install apps #
##################

# Copy rootfs
COPY rootfs /

# Modules
ARG MODULES="00-banner.sh"

# Automatic modules download
RUN if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) >/dev/null; fi \
    && if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) >/dev/null; fi \
    && apt-get update && apt-get install -yqq --no-install-recommends ca-certificates || apk add --no-cache ca-certificates >/dev/null || true \
    && mkdir -p /etc/cont-init.d \
    && for scripts in $MODULES; do echo "$scripts" && curl -f -L -s -S "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/$scripts" -o /etc/cont-init.d/"$scripts" && [ "$(sed -n '/\/bin/p;q' /etc/cont-init.d/"$scripts")" != "" ] || (echo "script failed to install $scripts" && exit 1); done \
    && chmod -R 755 /etc/cont-init.d || printf '%s\n' "${MODULES}" >/MODULESFILE

# Manual apps
ENV PACKAGES=""

# Automatic apps & bashio
RUN if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) >/dev/null; fi \
    && if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) >/dev/null; fi \
    && curl -f -L -s -S "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/automatic_packages.sh" --output /automatic_packages.sh \
    && chmod 777 /automatic_packages.sh \
    && eval /./automatic_packages.sh "${PACKAGES:-}" \
    && rm /automatic_packages.sh || printf '%s\n' "${PACKAGES:-}" > /ENVFILE

################
# 4 Entrypoint #
################

############
# 5 Labels #
############

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${APP_NAME}" \
    io.hass.description="${APP_NAME} Add-on for Home Assistant" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Wouter" \
    org.label-schema.description="${APP_NAME} Add-on for Home Assistant" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name="${APP_NAME}" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://github.com/alexbelgium/hassio-addons/${APP_ID}" \
    org.label-schema.usage="https://github.com/alexbelgium/hassio-addons/tree/master/${APP_ID}/README.md" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-url="https://github.com/alexbelgium/hassio-addons/${APP_ID}" \
    org.label-schema.vendor="Alex Belgium's Add-ons for Home Assistant"
