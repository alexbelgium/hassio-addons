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
FROM wiserain/flexget:latest

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=SC2016
RUN \
    # Set password
    files="$(grep -sril "set FG_WEBUI_PASSWD" /etc/cont-init.d /etc/s6-overlay/s6-rc.d)" \
    && sed -i 's/bash/bashio/g' "$files" \
    && sed -i 's/# set FG_WEBUI_PASSWD/if bashio::config.has_value "WebuiPass"; then FG_WEBUI_PASSWD=$(bashio::config "WebuiPass"); else FG_WEBUI_PASSWD=""; fi/g' "$files" \
    && sed -i 's/# install custom plugins/if bashio::config.has_value "FG_PLUGINS"; then FG_PLUGINS=$(bashio::config "FG_PLUGINS"); else FG_PLUGINS=""; fi/g' "$files"

# Global LSIO modifications
ARG CONFIGLOCATION="/config/addons_config/flexget"
# hadolint ignore=SC2015, SC2013
RUN \
    # Avoid custom-init.d duplications
    for file in $(grep -sril 'Potential tampering with custom' /etc/cont-init.d /etc/services.d /etc/s6-overlay/s6-rc.d); do rm -f "$file"; done \
    \
    # Create new config folder if needed
    && for file in $(grep -srl "PUID:-911" /etc/cont-init.d /etc/s6-overlay/s6-rc.d); do sed -i "1a mkdir -p $CONFIGLOCATION" "$file"; done \
    \
    # Allow UID and GID setting
    && for file in $(grep -srl "PUID:-911" /etc/cont-init.d /etc/s6-overlay/s6-rc.d); do sed -i 's/bash/bashio/g' "$file" && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' "$file" && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' "$file"; done \
    \
    # Correct config location
    && for file in $(grep -Esril '/config[ /]|/config$' /etc/logrotate.d /defaults /etc/cont-init.d /etc/services.d /etc/s6-overlay/s6-rc.d); do sed -i "s=/config=$CONFIGLOCATION=g" "$file"; done \
    \
    # Avoid changing /config permissions
    && for file in $(awk '/chown.*abc:abc.*\\/,/.*\/config( |$)/{print FILENAME}' /etc/services.d/*/run /etc/cont-init.d/* /etc/s6-overlay/s6-rc.d/*/run); do sed -i "/abc:abc/d" "$file" && sed -i "/\/config$/d" "$file"; done

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /

# Corrects permissions for s6 v3
RUN if [ -d /etc/cont-init.d ]; then chmod -R 755 /etc/cont-init.d; fi && \
    if [ -d /etc/services.d ]; then chmod -R 755 /etc/services.d; fi && \
    if [ -f /entrypoint.sh ]; then chmod 755 /entrypoint.sh; fi

# Modules
ARG MODULES="00-banner.sh 00-global_var.sh"

# Automatic modules download
RUN if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) >/dev/null; fi \
    && if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) >/dev/null; fi \
    && apt-get update && apt-get install -yqq --no-install-recommends ca-certificates || apk add --no-cache ca-certificates >/dev/null || true \
    && mkdir -p /etc/cont-init.d \
    && for scripts in $MODULES; do echo "$scripts" && curl -f -L -s -S "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/$scripts" -o /etc/cont-init.d/"$scripts" && [ "$(sed -n '/\/bin/p;q' /etc/cont-init.d/"$scripts")" != "" ] || (echo "script failed to install $scripts" && exit 1); done \
    && chmod -R 755 /etc/cont-init.d || printf '%s\n' "${MODULES}" >/MODULESFILE

# Manual apps
ENV PACKAGES="jq \
    curl \
    cifs-utils"

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

#RUN chmod 777 /entrypoint.sh
#WORKDIR /
#ENTRYPOINT [ "/usr/bin/env" ]
#CMD [ "/entrypoint.sh" ]

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
