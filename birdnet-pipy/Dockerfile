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
FROM node:20-alpine AS frontend-builder

ARG BIRDNET_PIPY_VERSION=main

RUN apk add --no-cache curl tar
RUN mkdir -p /src \
    && curl -fsSL "https://codeload.github.com/Suncuss/BirdNET-PiPy/tar.gz/refs/heads/${BIRDNET_PIPY_VERSION}" \
        | tar -xz -C /src --strip-components=1

WORKDIR /src/frontend
RUN npm ci --prefer-offline
RUN npm run build

FROM ${BUILD_FROM}

ARG BIRDNET_PIPY_VERSION=main

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

USER root

##################
# 3 Install apps #
##################

# Copy local files
COPY rootfs/ /
RUN find /etc -type f \( -name "*.sh" -o -path "*/services.d/*/run" \) -exec chmod +x {} \;

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES="00-banner.sh 01-custom_script.sh 00-global_var.sh"

# Automatic modules download
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" "/ha_automodules.sh"
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="python3 python3-pip python3-venv build-essential ffmpeg sox libpulse0 icecast2 nginx jq curl"

# Automatic apps & bashio
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" "/ha_autoapps.sh"
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

RUN mkdir -p /app
COPY --from=frontend-builder /src/backend/ /app/
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv "${VIRTUAL_ENV}"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
RUN pip install --no-cache-dir --extra-index-url https://www.piwheels.org/simple -r /app/requirements.txt

# Patch service hostnames for single-container usage
RUN sed -i \
    -e "s/API_HOST = 'api'/API_HOST = '127.0.0.1'/" \
    -e "s/BIRDNET_HOST = 'model-server'/BIRDNET_HOST = '127.0.0.1'/" \
    /app/config/settings.py

COPY --from=frontend-builder /src/deployment/audio/scripts/start-icecast.sh /usr/local/bin/start-icecast.sh
RUN chmod 755 /usr/local/bin/start-icecast.sh

COPY --from=frontend-builder /src/frontend/dist /usr/share/nginx/html

################
# 4 Entrypoint #
################

# Add entrypoint
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"
RUN chmod 777 /ha_entrypoint.sh

# Install bashio
ENV PATH="/usr/bin:${PATH}"
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/bashio-standalone.sh" "/usr/local/lib/bashio-standalone.sh"
RUN chmod 0755 /usr/local/lib/bashio-standalone.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/bashio-router.sh" "/usr/bin/bashio"
RUN chmod 0755 /usr/bin/bashio

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

####################
# 6 HealthcheckNOT #
####################
