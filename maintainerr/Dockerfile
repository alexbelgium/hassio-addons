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

# ARGs used in FROM must be declared before any FROM instruction
ARG BUILD_UPSTREAM="3.3.0"

############################
# 0) Tools stage           #
############################
# Build a small payload with gosu (for privilege dropping) and its shared libs
FROM alpine:3.22 AS ha_tools

RUN apk add --no-cache \
    gosu \
    pax-utils

RUN set -eux; \
    mkdir -p /out; \
    for bin in /usr/bin/gosu; do \
      mkdir -p "/out$(dirname "$bin")"; \
      cp -a "$bin" "/out$bin"; \
      lddtree -l "$bin" | while read -r dep; do \
        case "$dep" in \
          /lib/ld-musl-*.so.1) \
            continue ;; \
          /*) \
            mkdir -p "/out$(dirname "$dep")"; \
            cp -a "$dep" "/out$(dirname "$dep")/"; \
            ;; \
        esac; \
      done; \
    done

#################
# 1 Build Image #
#################

ARG BUILD_FROM
ARG BUILD_VERSION
FROM ghcr.io/maintainerr/maintainerr:${BUILD_UPSTREAM}

##################
# 2 Modify Image #
##################

USER root

# Bring in gosu from tools stage
COPY --from=ha_tools /out/ /

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /
RUN chmod +x /entrypoint.sh \
    && find /etc/cont-init.d /etc/cont-finish.d -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Install bashio standalone
RUN BASHIO_VERSION="0.14.3" && \
    mkdir -p /tmp/bashio && \
    curl -f -L -s -S "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" | tar -xzf - --strip 1 -C /tmp/bashio && \
    mv /tmp/bashio/lib /usr/lib/bashio && \
    ln -s /usr/lib/bashio/bashio /usr/bin/bashio && \
    rm -rf /tmp/bashio

# Modules
ARG MODULES="00-banner.sh 01-custom_script.sh"

# Automatic modules download
COPY ha_automodules.sh /ha_automodules.sh
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="nginx"

# Automatic apps & bashio
COPY ha_autoapps.sh /ha_autoapps.sh
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

COPY bashio-standalone.sh /usr/local/lib/bashio-standalone.sh
RUN chmod 0755 /usr/local/lib/bashio-standalone.sh

# Use our wrapper as entrypoint (replaces original /opt/app/start.sh)
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

ENV HEALTH_PORT="6246" \
    HEALTH_URL=""
HEALTHCHECK \
    --interval=5s \
    --retries=5 \
    --start-period=60s \
    --timeout=25s \
    CMD curl -A "HealthCheck: Docker/1.0" -s -f "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" &>/dev/null || exit 1
