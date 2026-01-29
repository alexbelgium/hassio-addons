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

ARG BUILD_VERSION
ARG BUILD_FROM
FROM ${BUILD_FROM}
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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
RUN find . -type f \( -name "*.sh" -o -name "run" \) -print -exec chmod +x {} \;

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES=""

# Automatic modules download
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" "/ha_automodules.sh"
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="mariadb-client"

# Meilisearch
ARG MEILISEARCH_VERSION="v1.25.0"
RUN set -eux && \
    DETECTED_ARCH="${BUILD_ARCH:-$(uname -m)}" && \
    case "${DETECTED_ARCH}" in \
        amd64|x86_64) MEILI_ARCH="linux-amd64" ;; \
        aarch64|arm64) MEILI_ARCH="linux-aarch64" ;; \
        *) echo "Unsupported architecture: ${DETECTED_ARCH}" >&2 && exit 1 ;; \
    esac && \
    TMP_DIR="$(mktemp -d)" && \
    BASE_URL="https://github.com/meilisearch/meilisearch/releases/download/${MEILISEARCH_VERSION}" && \
    if curl -fsSL -o "${TMP_DIR}/meilisearch.tar.gz" "${BASE_URL}/meilisearch-${MEILI_ARCH}.tar.gz"; then \
        tar -xzf "${TMP_DIR}/meilisearch.tar.gz" -C "${TMP_DIR}" && \
        MEILI_BIN="$(find "${TMP_DIR}" -maxdepth 1 -type f -name 'meilisearch' -print -quit)" && \
        if [ -z "${MEILI_BIN}" ]; then \
            echo "Unable to locate Meilisearch binary in archive" >&2; \
            exit 1; \
        fi && \
        mv "${MEILI_BIN}" /usr/local/bin/meilisearch; \
    else \
        curl -fsSL -o "${TMP_DIR}/meilisearch" "${BASE_URL}/meilisearch-${MEILI_ARCH}" && \
        mv "${TMP_DIR}/meilisearch" /usr/local/bin/meilisearch; \
    fi && \
    chmod 755 /usr/local/bin/meilisearch && \
    rm -rf "${TMP_DIR}" && \
    mkdir -p /data/meilisearch

# Automatic apps & bashio
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" "/ha_autoapps.sh"
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Fix Monica issues
RUN grep -rl "could you verify your email address by clicking on the link we just emailed to you" /var/www/html 2>/dev/null | \
    while IFS= read -r file; do \
        sed -i "s|we just emailed to you|that you can find in the addon log, starting with Please click the button below to verify your email address|g" "$file"; \
    done && \
    \
    # Fix dummy password
    sed -i "s|admin123|Changeme123\\!|g" /var/www/html/app/Console/Commands/Local/SetupDummyAccount.php

# Add entrypoint
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"
RUN chmod 777 /ha_entrypoint.sh

# Install bashio
#ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/bashio-standalone.sh" "/usr/local/lib/bashio-standalone.sh"
#RUN chmod 0755 /usr/local/lib/bashio-standalone.sh
#ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/bashio-router.sh" "/usr/bin/bashio"
#RUN chmod 0755 /usr/bin/bashio

COPY rootfs/ /
RUN find . -type f \( -name "*.sh" -o -name "run" \) -print -exec chmod +x {} \;


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

ENV HEALTH_PORT="8080" \
    HEALTH_URL=""
HEALTHCHECK \
    --interval=5s \
    --retries=5 \
    --start-period=30s \
    --timeout=25s \
    CMD curl -A "HealthCheck: Docker/1.0" -s -f "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" &>/dev/null || exit 1
