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
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0


ENV LANG C.UTF-8

# Environment variables
ENV APP_ID="spotweb"
ENV APP_NAME="Spotweb"
ENV APP_DIR="/app"
ENV BUILD_UPSTREAM="1.5.8"

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base
# hadolint ignore=DL3003
# Install app dependencies
ENV PHPVERS="83"
RUN apk -U update && \
    # hadolint ignore=DL3017
    apk -U upgrade && \
    apk -U add --no-cache \
    git \
    nginx \
    php$PHPVERS \
    php$PHPVERS-fpm \
    php$PHPVERS-curl \
    php$PHPVERS-dom \
    php$PHPVERS-gettext \
    php$PHPVERS-xml \
    php$PHPVERS-simplexml \
    php$PHPVERS-zip \
    php$PHPVERS-zlib \
    php$PHPVERS-gd \
    php$PHPVERS-openssl \
    php$PHPVERS-mysqli \
    php$PHPVERS-pdo \
    php$PHPVERS-pdo_mysql \
    php$PHPVERS-pgsql \
    php$PHPVERS-pdo_pgsql \
    php$PHPVERS-sqlite3 \
    php$PHPVERS-pdo_sqlite \
    php$PHPVERS-json \
    php$PHPVERS-mbstring \
    php$PHPVERS-ctype \
    php$PHPVERS-opcache \
    php$PHPVERS-session \
    mariadb-client \
    \
    && mkdir -p /app \
    # Install latest Spotweb release
    && git clone --depth=1 https://github.com/spotweb/spotweb.git /app \
    # spotweb needs a timezone set in the php.ini
    # TODO: Can we dynamically set the correct timezone here ?
    && sed -i "s/;date.timezone =/date.timezone = \"Europe\/Amsterdam\"/g" /etc/php*/php.ini \
    && mkdir /app/cache \
    && mkdir /var/tmp/nginx

# Corrects permissions for /app directory
RUN if [ -d /app ]; then chown -R nginx /app; fi

##################
# 3 Install apps #
##################

# Copy local files
COPY rootfs/ /

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES="01-custom_script.sh"

# Automatic modules download
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" "/ha_automodules.sh"
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES=""

# Automatic apps & bashio
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" "/ha_autoapps.sh"
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Add entrypoint
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"

# Entrypoint modifications
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint_modif.sh" "/ha_entrypoint_modif.sh"
RUN chmod 777 /ha_entrypoint.sh /ha_entrypoint_modif.sh && /ha_entrypoint_modif.sh && rm /ha_entrypoint_modif.sh

# Standalone bashio command
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/bashio-standalone.sh" "/.bashio-standalone.sh"
RUN chmod 777 /.bashio-standalone.sh

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
