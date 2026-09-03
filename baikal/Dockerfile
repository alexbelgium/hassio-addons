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

ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="0.12.1"

# ckulka/baikal-docker, which builds the base image, stopped publishing new
# Baikal versions at 0.10.1 : the base image is used for its runtime only
# (nginx, php-fpm, msmtp) and the application comes from the release published
# by sabre-io itself
FROM alpine:3.21 AS baikal
ARG BUILD_UPSTREAM
RUN apk add --no-cache curl unzip \
    && curl -f -s -S -L -o /tmp/baikal.zip "https://github.com/sabre-io/Baikal/releases/download/${BUILD_UPSTREAM}/baikal-${BUILD_UPSTREAM}.zip" \
    && unzip -q /tmp/baikal.zip -d / \
    && rm /tmp/baikal.zip

FROM ${BUILD_FROM}

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

# Ship the Baikal release instead of the one bundled in the base image
RUN rm -rf /var/www/baikal
COPY --from=baikal --chown=nginx:nginx /baikal /var/www/baikal

# Home Assistant asks for an expanded time range, and Baikal stores
# cal:calendar-timezone as a bare timezone name rather than as the VTIMEZONE
# object sabre/dav expects, so sabre/dav raises a ParseException and answers
# 500 (sabre-io/Baikal#1241 and sabre-io/dav#1318, both still open). Read the
# value as a timezone name instead. The two checks turn a release that moved
# this code into a failed build rather than into an addon that Home Assistant
# cannot read.
# hadolint ignore=SC2016
RUN \
    DAVPLUGIN="/var/www/baikal/vendor/sabre/dav/lib/CalDAV/Plugin.php" \
    && sed -i '/^                \/\/ This property contains a VCALENDAR with a single$/,/^                \$vtimezoneObj->destroy();$/c\                $calendarTimeZone = new DateTimeZone($tzResult[$tzProp]);' "$DAVPLUGIN" \
    && grep -qxF '                $calendarTimeZone = new DateTimeZone($tzResult[$tzProp]);' "$DAVPLUGIN" \
    && ! grep -qxF '                $calendarTimeZone = $vtimezoneObj->VTIMEZONE->getTimeZone();' "$DAVPLUGIN"

# Image specific modifications
# hadolint ignore=SC2015, SC2013, SC2086
RUN \
    for file in $(grep -sril "/var/www/baikal" /etc /var /usr); do sed -i "s=/var/www/baikal=/data=g" $file || true; done

##################
# 3 Install apps #
##################
# Copy local files
COPY rootfs/ /
RUN find . -type f \( -name "*.sh" -o -name "run" -o -name "finish" \) -print -exec chmod +x {} \;

# Uses /bin for compatibility purposes
# hadolint ignore=SC2114
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES="00-banner.sh 01-custom_script.sh"

# Automatic modules download
COPY ha_automodules.sh /ha_automodules.sh
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ARG PACKAGES=""

# Automatic apps & bashio
COPY ha_autoapps.sh /ha_autoapps.sh
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Add entrypoint
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
COPY ha_entrypoint.sh /ha_entrypoint.sh
RUN chmod 777 /ha_entrypoint.sh

# Install bashio
COPY bashio-standalone.sh /usr/local/lib/bashio-standalone.sh
RUN chmod 0755 /usr/local/lib/bashio-standalone.sh

WORKDIR "/data"

ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "/ha_entrypoint.sh" ]

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
ENV BUILD_VERSION="${BUILD_VERSION}"
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

#################
# 6 Healthcheck #
#################

# Avoid spamming logs
# hadolint ignore=SC2016
RUN \
    # Handle Apache configuration
    if [ -d /etc/apache2/sites-available ]; then \
        for file in /etc/apache2/sites-*/*.conf; do \
            sed -i '/<VirtualHost/a \ \n    # Match requests with the custom User-Agent "HealthCheck" \n    SetEnvIf User-Agent "HealthCheck" dontlog \n    # Exclude matching requests from access logs \n    CustomLog ${APACHE_LOG_DIR}/access.log combined env=!dontlog' "$file"; \
        done; \
    fi && \
    \
    # Handle Nginx configuration
    if [ -f /etc/nginx/nginx.conf ]; then \
        awk '/http \{/{print; print "map $http_user_agent $dontlog {\n  default 0;\n  \"~*HealthCheck\" 1;\n}\naccess_log /var/log/nginx/access.log combined if=$dontlog;"; next}1' /etc/nginx/nginx.conf > /etc/nginx/nginx.conf.new && \
        mv /etc/nginx/nginx.conf.new /etc/nginx/nginx.conf; \
    fi

ENV HEALTH_PORT="80" \
    HEALTH_URL=""
HEALTHCHECK \
    --interval=5s \
    --retries=5 \
    --start-period=30s \
    --timeout=25s \
    CMD curl -A "HealthCheck: Docker/1.0" -s -f "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" &>/dev/null || exit 1
