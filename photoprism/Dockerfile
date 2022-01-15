#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#           _.------.
#       _.-`    ('>.-`"""-.
# '.--'`       _'`   _ .--.)
#    -'         '-.-';`   `
#    ' -      _.'  ``'--. 
#        '---`    .-'""`
#               /`
#=== Home Assistant Addon ===#

#################
# 0 Helper code #
#################
# hadolint ignore=DL3006
# hadolint ignore=DL3008
# hadolint ignore=DL3009
# hadolint ignore=DL3018

#################
# 1 Build Image #
#################

ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="20220107"
FROM photoprism/photoprism:latest

##################
# 2 Modify Image #
##################

RUN \
    # Create directories
    mkdir -m 777 -p \
    /data/photoprism/originals \
    /data/photoprism/import \
    /data/photoprism/storage/config \
    /data/photoprism/backup \
    /data/photoprism/storage/cache && \
    chown -Rf photoprism:photoprism /data/photoprism && \
    chmod -Rf a+rwx /data/photoprism && \
    # rename entrypoint
    mv /entrypoint.sh /entrypoint_photoprism.sh


##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /

# Modules
ARG MODULES="00-banner.sh 92-local_mounts.sh 92-smb_mounts.sh"

# Automatic modules download
RUN if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash); fi && \
    if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl); fi && \
    mkdir -p /tmpscripts /etc/cont-init.d && \
    for scripts in $MODULES; do curl -L -f -s "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/zzz_templates/$scripts" -o /tmpscripts/"$scripts"; done  && \
    if [ -d /etc/cont-init.d ]; then /bin/cp -rf /tmpscripts/* /etc/cont-init.d/ && chmod -R 755 /etc/cont-init.d; fi && \
    rm -rf /tmpscripts || printf '%s\n' "${MODULES:-}" > /MODULESFILE

# Manual apps
ENV PACKAGES="jq \
    curl \
    cifs-utils \
    keyutils \
    coreutils"

# Automatic apps & bashio
RUN if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) >/dev/null; fi && \
    if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) >/dev/null; fi && \
    curl -L -f -s "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/zzz_templates/automatic_packages.sh" --output /automatic_packages.sh && \
    chmod 777 /automatic_packages.sh && \
    eval /./automatic_packages.sh "${PACKAGES:-}" && \
    rm /automatic_packages.sh || printf '%s\n' "${PACKAGES:-}" > /ENVFILE

################
# 4 Entrypoint #
################

RUN chmod 777 /entrypoint.sh
ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "/entrypoint.sh" ]

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
