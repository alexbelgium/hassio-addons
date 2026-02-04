#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#           _.------.
#       _.-`    ('>.-`"1.6.0-bullseye""-.
# '.--'`       _'`   _ .--.)
#    -'         '-.-';`   `
#    ' -      _.'  ``'--.
#        '---`    .-'"1.6.0-bullseye"`
#               /`
#=== Home Assistant Addon ===#

#################
# 1 Build Image #
#################

ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

WORKDIR /config

# hadolint ignore=SC2016
RUN \
    # Enable extensions
    sed -i 's|#!/usr/bin/with-contenv sh|#!/usr/bin/with-contenv bashio|g' /etc/cont-init.d/50-extensions.sh \
    && sed -i 's|$EXTENSIONS|$(bashio::config "EXTENSIONS")|g' /etc/cont-init.d/50-extensions.sh \
    \
    # Correct transfer
    && sed -i 's|cp -rn /app/guacamole|cp -rn /app/guacamole/*|g' /etc/cont-init.d/* \
    \
    # avoid error
    && sed -i 's|(cat /config/\.database-version)|(cat /config/\.database-version \&>/dev/null)|g' /etc/cont-init.d/* \
    && sed -i 's|(cat /config/\.database-version)|(cat /config/\.database-version \&>/dev/null)|g' /etc/services.d/*/run \
    \
    # Allow syslog
    && mkdir -p /tmpsock \
    && python3 -c "import socket as s; sock = s.socket(s.AF_UNIX); sock.bind('/tmpsock/syslog')" \
    && sed -i "s|s6-socklog -d3 -U -t3000|s6-socklog -d3 -U -t3000 -x /tmpsock/syslog|g" /etc/s6-overlay/s6-rc.d/syslogd/run \
    \
    # Allow custom fonts
    && sed -i '\|<dir>/usr/share/fonts</dir>|a\ \ \ \ \ \ \ \ <dir>/config/fonts</dir>' /etc/fonts/fonts.conf \
    \
    # Avoid https://github.com/alexbelgium/hassio-addons/issues/659
    && rm -r /run/shm \
    && sed -i "1a set +e" /etc/services.d/*/run

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /
RUN find . -type f \( -name "*.sh" -o -name "run" -o -name "finish" \) -print -exec chmod +x {} \;

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES="00-banner.sh 01-custom_script.sh"

# Automatic modules download
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" "/ha_automodules.sh"
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="nginx"

# Automatic apps & bashio
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" "/ha_autoapps.sh"
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Add entrypoint
#ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"
RUN chmod 777 /ha_entrypoint.sh

# Install bashio
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/bashio-standalone.sh" "/usr/local/lib/bashio-standalone.sh"
RUN chmod 0755 /usr/local/lib/bashio-standalone.sh

#WORKDIR /data
ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "/ha_entrypoint.sh" ]
#SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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

ENV HEALTH_PORT="8080" \
    HEALTH_URL="1.6.0-bullseye"
HEALTHCHECK \
    --interval=5s \
    --retries=5 \
    --start-period=30s \
    --timeout=25s \
    CMD curl --fail "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" &>/dev/null || exit 1
