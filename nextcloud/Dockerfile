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
ARG BUILD_ARCH
ARG BUILD_UPSTREAM="latest"
FROM ${BUILD_FROM}${BUILD_UPSTREAM}

##################
# 2 Modify Image #
##################


# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

# Specific modifications
ARG CONFIGLOCATION="/config/data"
# hadolint ignore=SC2015,SC2086
RUN \
    # Change default data location
    for file in $(grep -Esril "/data" /etc /defaults); do sed -Ei "s=(/data)+(/| |$|\"|\')=$CONFIGLOCATION\2=g" $file; done && \
    \
    # modify data limits file
    sed -i \
    -e '/upload_max_filesize/c upload_max_filesize=8192M' \
    -e '/post_max_size/c post_max_size=8192M' \
    -e '/max_execution_time/c max_execution_time=3600' \
    /etc/php*/php.ini && \
    \
    sed -i \
    -e '/upload_max_filesize/c upload_max_filesize=8192M' \
    -e '/post_max_size/c post_max_size=8192M' \
    -e '/max_execution_time/c max_execution_time=3600' \
    /etc/php*/conf.d/nextcloud.ini && \
    \
    # modify nginx limits file
    sed -i \
    -e '/client_max_body_size/c client_max_body_size 8192M;' \
    -e '/post_max_size/c client_body_timeout 900s;' \
    /defaults/nginx/site-confs/default.conf.sample && \
    \
    # Change location of log
    sed -i "s|s6-setuidgid abc php -f /config/www/nextcloud/cron.php|(s6-setuidgid abc php -f /config/www/nextcloud/cron.php) \&>/proc/1/fd/1|g" /etc/crontabs/root && \
    \
    # Disable data check at installation
    echo "echo \"... Disabling check_data_directory_permissions\"" >> /etc/s6-overlay/s6-rc.d/init-nextcloud-config/run && \
    echo "sed -i \"/check_data_directory_permissions/d\" /config/www/nextcloud/config/config.php || true" >> /etc/s6-overlay/s6-rc.d/init-nextcloud-config/run && \
    echo "sed -i \"/datadirectory/a\ \ 'check_data_directory_permissions' => false,\" /config/www/nextcloud/config/config.php || true" >> /etc/s6-overlay/s6-rc.d/init-nextcloud-config/run

# Global LSIO modifications
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_lsio.sh" "/ha_lsio.sh"
ARG CONFIGLOCATION="/data/config"
RUN chmod 744 /ha_lsio.sh && if grep -qr "lsio" /etc; then /ha_lsio.sh "$CONFIGLOCATION"; fi && rm /ha_lsio.sh

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES="00-banner.sh 01-custom_script.sh 00-local_mounts.sh 00-smb_mounts.sh"

# Automatic modules download
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" "/ha_automodules.sh"
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="inotify-tools gcompat ffmpeg imagemagick"

# Automatic apps & bashio
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" "/ha_autoapps.sh"
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

VOLUME ["/share", "/ssl", "/data", "/media"]

################
# 4 Entrypoint #
################

# Add entrypoint
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"

# Entrypoint modifications
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint_modif.sh" "/ha_entrypoint_modif.sh"
RUN chmod 777 /ha_entrypoint.sh /ha_entrypoint_modif.sh && /ha_entrypoint_modif.sh && rm /ha_entrypoint_modif.sh

# Correct modifications
ARG CONFIGLOCATION="/www/nextcloud/config"
# hadolint ignore=SC2015, SC2013, SC2086, SC2016
RUN \
    # Correct erroneous modifications
    for file in $(grep -Esril "/www/nextcloud/data/config" /etc /defaults); do sed -Ei "s=(/www/nextcloud/data/config)+(/| |$|\"|\')=$CONFIGLOCATION\2=g" $file; done && \
    for file in $(grep -Esril "/data/data" /etc /defaults); do sed -Ei "s=(/data/data)+(/| |$|\"|\')=/data\2=g" $file; done && \
    \
    # Correct nginx files
    sed -i "/Strict-Transport-Security/d" /defaults/nginx/site-confs/default.conf.sample && \
    sed -i '1h;1!H;$!d;g;s/\(.*\)}/\1/' /defaults/nginx/site-confs/default.conf.sample && \
    cat /defaults/nginx_addition >> /defaults/nginx/site-confs/default.conf.sample && \
    \
    # Run custom scripts after installation
    echo "mv /scripts/* /etc/cont-init.d/ && /./ha_entrypoint.sh" >> /etc/s6-overlay/s6-rc.d/init-nextcloud-config/run

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
    HEALTH_URL="/robots.txt"
HEALTHCHECK \
    --interval=5s \
    --retries=5 \
    --start-period=720s \
    --timeout=45s \
    CMD curl -A "HealthCheck: Docker/1.0" -s -f "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" &>/dev/null || curl --fail http://127.0.0.1:443 || exit 1
