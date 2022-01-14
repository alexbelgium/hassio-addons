#==========================#
# ALEXBELGIUM'S DOCKERFILE #
#==========================#
#           _.------.
#       _.-`    ('>.-`"""-.
# '.--'`       _'`   _ .--.)
#    -'         '-.-';`   `
#    ' -      _.'  ``'--. 
#        '---`    .-'""`
#               /`

#################
# 1 Build Image #
#################

ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_ARCH
ARG BUILD_UPSTREAM="23.0.0"
FROM ${BUILD_FROM}

##################
# 2 Modify Image #
##################

ENV NEXTCLOUD_PATH="/data/config/www/nextcloud"

RUN \
    # Remove upstream files
    rm -rf /etc/cont-init.d/10-adduser /etc/cont-init.d/30-keygen /etc/cont-init.d/40-config /etc/cont-init.d/50-install /etc/cont-init.d/60-memcache /etc/cont-init.d/70-aliases \
    # Make permissions
    && chmod +x /defaults/nextcloud-perms.sh \
    # default folders
    && sed -i "s|data|share/nextcloud|g" /etc/cont-init.d/* \
    && sed -i "s|config|data/config|g" /etc/cont-init.d/* \
    && sed -i "s|data|share/nextcloud|g" /etc/services.d/nginx/* \
    && sed -i "s|config|data/config|g" /etc/services.d/nginx/* \
    # modify data limits files
    # -e 's/memory_limit=512M/memory_limit=1024M/g' \
    && sed -i \
    -e 's/upload_max_filesize=1024M/upload_max_filesize=10240M/g' \
    -e 's/post_max_size=1024M/post_max_size=10240M/g' \
    /etc/php7/php.ini \
    && sed -i "s|client_max_body_size 512M;|client_max_body_size 10240M;|g" /defaults/default

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /

# Modules
ARG MODULES="00-banner.sh"

# Automatic modules download
RUN if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash); fi && \
    if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl); fi && \
    mkdir -p /tmpscripts /etc/cont-init.d && \
    for scripts in $MODULES; do curl -L -f -s "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/zzz_templates/$scripts" -o /tmpscripts/"$scripts"; done  && \
    if [ -d /etc/cont-init.d ]; then /bin/cp -rf /tmpscripts/* /etc/cont-init.d/ && chmod -R 755 /etc/cont-init.d; fi && \
    rm -rf /tmpscripts || printf '%s\n' "${MODULES:-}" > /MODULESFILE

# Manual apps
ENV PACKAGES="curl jq wget"

# Automatic apps & bashio
RUN if ! command -v bash >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash); fi && \
    if ! command -v curl >/dev/null 2>/dev/null; then (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl); fi && \
    curl -L -f -s "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/zzz_templates/automatic_packages.sh" --output /automatic_packages.sh && \
    chmod 777 /automatic_packages.sh && \
    /automatic_packages.sh "${PACKAGES:-}" && \
    rm /automatic_packages.sh || printf '%s\n' "${PACKAGES:-}" > /ENVFILE

VOLUME ["/share", "/ssl", "/data", "/media"]

################
# 4 Entrypoint #
################

#RUN chmod 777 /entrypoint.sh
#WORKDIR /
#ENTRYPOINT [ "/usr/bin/env" ]
#CMD [ "/entrypoint.sh" ]
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
