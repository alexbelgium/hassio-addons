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
ARG BUILD_UPSTREAM="1.9.2"
FROM ${BUILD_FROM}${BUILD_UPSTREAM}

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /

# Corrects permissions for s6 v3
RUN if [ -d /etc/cont-init.d ]; then chmod -R 755 /etc/cont-init.d; fi && \
    if [ -d /etc/services.d ]; then chmod -R 755 /etc/services.d; fi && \
    if [ -f /entrypoint.sh ]; then chmod 755 /entrypoint.sh; fi

ENV \
    PAPERLESS_DATA_DIR=/config/addons_config/paperless_ng \
    PAPERLESS_MEDIA_ROOT=/config/addons_config/paperless_ng/media \
    PAPERLESS_CONSUMPTION_DIR=/config/addons_config/paperless_ng/consume

# Modify image
# hadolint ignore=SC2016
RUN \
    sed -i 's|usr/bin/env bash|usr/bin/env bashio|g' /sbin/docker-entrypoint.sh && \
    # Run entrypoint
    sed -i '2i /./entrypoint.sh' /sbin/docker-entrypoint.sh && \
    # Set variables
    sed -i '2i bashio::log.info "Defining variables"' /sbin/docker-entrypoint.sh && \
    sed -i '2i if bashio::config.has_value "PUID"; then export USERMAP_UID=$(bashio::config "PUID"); fi' /sbin/docker-entrypoint.sh && \
    sed -i '2i if bashio::config.has_value "PGID"; then export USERMAP_GID=$(bashio::config "PGID"); fi' /sbin/docker-entrypoint.sh && \
    sed -i '2i if bashio::config.has_value "TZ"; then export PAPERLESS_TIME_ZONE=$(bashio::config "TZ"); fi' /sbin/docker-entrypoint.sh && \
    sed -i '2i if bashio::config.has_value "OCRLANG"; then export PAPERLESS_OCR_LANGUAGES=$(bashio::config "OCRLANG"); fi' /sbin/docker-entrypoint.sh && \
    sed -i '2i if bashio::config.has_value "PAPERLESS_OCR_MODE"; then export PAPERLESS_OCR_MODE=$(bashio::config "PAPERLESS_OCR_MODE"); fi' /sbin/docker-entrypoint.sh

# Modules
ARG MODULES="00-banner.sh 92-local_mounts.sh 92-smb_mounts.sh 90-config_yaml.sh"

# Automatic modules download
RUN if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) >/dev/null; fi \
    && if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) >/dev/null; fi \
    && apt-get update && apt-get install -yqq --no-install-recommends ca-certificates || apk add --no-cache ca-certificates >/dev/null || true \
    && mkdir -p /etc/cont-init.d \
    && for scripts in $MODULES; do echo "$scripts" && curl -f -L -s -S "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/$scripts" -o /etc/cont-init.d/"$scripts" && [ "$(sed -n '/\/bin/p;q' /etc/cont-init.d/"$scripts")" != "" ] || (echo "script failed to install $scripts" && exit 1); done \
    && chmod -R 755 /etc/cont-init.d || printf '%s\n' "${MODULES}" >/MODULESFILE

# Manual apps
ENV PACKAGES="redis-server yamllint pip libxml2-dev libxslt-dev python-dev libjpeg-dev zlib1g-dev python3-dev build-essential"

# Automatic apps & bashio
# hadolint ignore=SC2015
RUN if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) >/dev/null; fi \
    && if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) >/dev/null; fi \
    && curl -f -L -s -S "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/automatic_packages.sh" --output /automatic_packages.sh \
    && chmod 777 /automatic_packages.sh \
    && eval /./automatic_packages.sh "${PACKAGES:-}" \
    && rm /automatic_packages.sh || (printf '%s\n' "${PACKAGES:-}" > /ENVFILE; \
    if [ -f /etc/s6-overlay/s6-rc.d/init-migrations/run ]; then chmod +x /etc/cont-init.d/00-aaa_dockerfile_backup.sh && sed -i "1a /./etc/cont-init.d/00-aaa_dockerfile_backup.sh" /etc/s6-overlay/s6-rc.d/init-migrations/run;fi)

################
# 4 Entrypoint #
################

RUN chmod 777 /entrypoint.sh
#WORKDIR /
#ENTRYPOINT [ "/usr/bin/env" ]
#ENTRYPOINT [ "/entrypoint.sh" ]
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
