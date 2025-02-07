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
ARG BUILD_UPSTREAM="20250126.1"
FROM ${BUILD_FROM}

##################
# 2 Modify Image #
##################

USER root

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

#ENV FIREFLY_III_PATH="/data/firefly"
#WORKDIR $FIREFLY_III_PATH

#RUN \
#    mkdir -p /scripts && \
#    mv /etc/entrypoint.d/11-execute-things.sh /scripts/

#RUN \
#    # Change data location
#    grep -rl "/var/www/html" /etc/ | xargs sed -i 's|/var/www/html|/data/firefly|g'

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
ARG MODULES="00-banner.sh 01-custom_script.sh 00-global_var.sh 01-config_yaml.sh"

# Automatic modules download
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" "/ha_automodules.sh"
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="cron bash sudo"

# Automatic apps & bashio
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" "/ha_autoapps.sh"
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Add entrypoint
#ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"

# Entrypoint modifications
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint_modif.sh" "/ha_entrypoint_modif.sh"
RUN chmod 777 /ha_entrypoint.sh /ha_entrypoint_modif.sh && /ha_entrypoint_modif.sh && rm /ha_entrypoint_modif.sh

# Adapt shebang
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN \
    # Run as www-data
    sed -i "s|/usr|sudo -Eu www-data /usr|g" /etc/s6*/s6*/php-fpm/run && \
    # Move execute things
    mkdir -p /scripts && \
    mv /etc/entrypoint.d/11-execute-things.sh /scripts/ && \
    # Allow passwordless root
    echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    # Change output lots
    sed -i "s|/proc/self/fd/2|/proc/1/fd/1|g" /etc/entrypoint.d/1-log-output-level.sh && \
    grep -rl "/proc/self/fd/2" /usr/local/etc | while read -r files; do sed -i "s|/proc/self/fd/2|/proc/1/fd/1|g" "$files"; done && \
    # Adapt files
    for files in /etc/cont-init.d/*; do sed -i "s|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g" "$files"; done
    #sed -i "s|/command/with-contenv bashio|/bin/bash bashio|g" /ha_entrypoint.sh && \

    # Execute entrypoint
    #sed -i "s|/usr/bin/env sh|/usr/bin/env bashio|g" /etc/entrypoint.d/11-execute-things.sh && \
    #chmod 777 /ha_entrypoint.sh && \
    #sed -i "1a sudo /./ha_entrypoint.sh" /etc/entrypoint.d/11-execute-things.sh
#RUN cat /ha_entrypoint.sh && \
#    sed -i "1i \#\!/bin/bash" /ha_entrypoint.sh

# Entrypoint
#RUN sed -i "1a \#\!/bin/bash bashio" /ha_entrypoint.sh
#RUN echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
#    chown -R www-data:www-data /etc/cont-init.d/* && \
#    chmod 777 /ha_entrypoint.sh && \
#    sed -i "s| sh| bashio|g" /etc/entrypoint.d/11-execute-things.sh && \
#    sed -i "1a source /ha_entrypoint.sh" /etc/entrypoint.d/11-execute-things.sh

#ENV ha_entry_source="true"

#USER www-data

#ENTRYPOINT [ "/usr/bin/env" ]
#CMD [ "/ha_entrypoint.sh" ]

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

ENV HEALTH_PORT="8080" \
    HEALTH_URL="/health"
HEALTHCHECK \
    --interval=5s \
    --retries=5 \
    --start-period=30s \
    --timeout=25s \
    CMD curl -A "HealthCheck: Docker/1.0" -s -f "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" &>/dev/null || exit 1
