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
ARG BUILD_UPSTREAM="5.1.1"
FROM ${BUILD_FROM}

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

# Environment variables
ENV \
    DEBIAN_FRONTEND="noninteractive"\
    LANG="C.UTF-8" \
    PS1="$(whoami)@$(hostname):$(pwd)$ " \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    TERM="xterm-256color" \
    HOME="/config" \
    XDG_CONFIG_HOME="/config" \
    XDG_DATA_HOME="/config"

# Image specific modifications
# hadolint ignore=DL4006
RUN \
    # Set download folder to /share
    sed -i 's|/downloads/|/share/qBittorrent/|g' /defaults/qBittorrent.conf \
    \
    # Remove fixed folders, allows connection to webUI
    && sed '11,13d' /defaults/qBittorrent.conf \
    && echo 'WebUI\HostHeaderValidation=false' >> /defaults/qBittorrent.conf \
    && echo 'WebUI\LocalHostAuth=false' >> /defaults/qBittorrent.conf \
    \
    # Add vuetorrent
    && curl -f -s -S -O -J -L "$(curl -f -s -L https://api.github.com/repos/WDaan/VueTorrent/releases | grep -o "http.*vuetorrent.zip" | head -1)" >/dev/null \
    && unzip -o vuetorrent.zip -d / >/dev/null \
    && rm vuetorrent.zip >/dev/null

# Global LSIO modifications
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_lsio.sh" "/ha_lsio.sh"
ARG CONFIGLOCATION="/config"
RUN chmod 744 /ha_lsio.sh && if grep -qr "lsio" /etc; then /ha_lsio.sh "$CONFIGLOCATION"; fi && rm /ha_lsio.sh

# ADD QBIT_MANAGE
#################

ENV QBM_DOCKER=True
ENV QBT_SKIP_QB_VERSION_CHECK=True
ENV qbt_skip_qb_version_check=true
ENV PYTHONUNBUFFERED=1

# halodint disable=DL3019,SC3010
RUN \
    apk add --no-cache git && \
    git clone --branch master https://github.com/StuffAnThings/qbit_manage.git /qbit_manage && \
    sed -i "/qbittorrent-api/d" /qbit_manage/pyproject.toml && \
    \
    # Install dependencies
    ## Allow python specific arch
    BUILD_ARCH=$(uname -m) && \
    echo "${BUILD_ARCH}" && \
    BUILD_ARCH=${BUILD_ARCH:-x86} && \
    if test "${BUILD_ARCH}" != "*amd64*"; then apk add --no-cache python3-dev; else apk add --no-cache python3; fi && \
    ln -sf python3 /usr/bin/python && \
    apk add --no-cache py3-pip gcc musl-dev && \
    pip3 install --user .

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
ARG MODULES="00-banner.sh 01-custom_script.sh 00-local_mounts.sh 00-smb_mounts.sh 90-dns_set.sh"

# Automatic modules download
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" "/ha_automodules.sh"
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

#RUN if [ -f /etc/s6-overlay/s6-rc.d/init-adduser ]; then for SCRIPTS in /etc/cont-init.d/*; do [ -e "$SCRIPTS" ] || continue \
#    && mkdir -p /abscripts && sed -i 's|/usr/bin/with-contenv bashio|/usr/bin/env bashio|g' "$SCRIPTS" \
#    && SCRIPTSNAME="$(basename "$SCRIPTS")" && mkdir /etc/s6-overlay/s6-rc.d/"$SCRIPTSNAME" && mv "$SCRIPTS" /etc/s6-overlay/s6-rc.d/"$SCRIPTSNAME"/run \
#    && echo "oneshot" > /etc/s6-overlay/s6-rc.d/"$SCRIPTSNAME"/type && echo "/etc/s6-overlay/s6-rc.d/$SCRIPTSNAME/run" > /etc/s6-overlay/s6-rc.d/"$SCRIPTSNAME"/up \
#    && chmod a+x /etc/s6-overlay/s6-rc.d/$SCRIPTSNAME/* ; done; fi

# Manual apps
ARG PACKAGES="wireguard-tools"

# Automatic apps & bashio
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" "/ha_autoapps.sh"
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

# Switch scripts from s6 v2 to v3
#RUN if [ -f /etc/s6-overlay/s6-rc.d/init-custom-file/run ]; then mkdir "/custom-cont-init.d" && for SCRIPTS in /etc/cont-init.d/*; do [ -e "$SCRIPTS" ] || continue \
#    && mv "$SCRIPTS" /custom-cont-init.d && chmod a+x /custom-cont-init.d/*; done; fi

################
# 4 Entrypoint #
################

# Add entrypoint
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"

# Entrypoint modifications
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint_modif.sh" "/ha_entrypoint_modif.sh"
RUN chmod 777 /ha_entrypoint.sh /ha_entrypoint_modif.sh && /ha_entrypoint_modif.sh && rm /ha_entrypoint_modif.sh

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

ENV HEALTH_PORT="" \
    HEALTH_URL=""
HEALTHCHECK \
    --interval=5s \
    --retries=5 \
    --start-period=30s \
    --timeout=25s \
    CMD pgrep qbittorrent || exit 1
