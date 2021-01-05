ARG BUILD_FROM=hassioaddons/base:8.0.6
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Copy yq
ARG BUILD_ARCH=amd64
COPY bin/yq_${BUILD_ARCH} /usr/bin/yq

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup base
# hadolint ignore=DL3003,SC2155
RUN \
    apk add --no-cache --virtual .build-dependencies \
        gnupg=2.2.23-r0 \
    \
    && apk add --no-cache \
        lua-resty-http=0.15-r0 \
        nginx-mod-http-lua=1.18.0-r1 \
        nginx=1.18.0-r1 \
    \
    && if [[ "${BUILD_ARCH}" = "aarch64" ]]; then ARCH="arm64"; fi \
    && if [[ "${BUILD_ARCH}" = "amd64" ]]; then ARCH="amd64"; fi \
    && if [[ "${BUILD_ARCH}" = "armhf" ]]; then ARCH="armv6"; fi \
    && if [[ "${BUILD_ARCH}" = "armv7" ]]; then ARCH="armv7"; fi \
    && if [[ "${BUILD_ARCH}" = "i386" ]]; then ARCH="386"; fi \
    \
    && curl -L -s \
        "https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.105.0-beta.2/AdGuardHome_linux_${ARCH}.tar.gz" \
        | tar zxvf - -C /opt/ \
    \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg \
        --batch \
        --keyserver pgp.key-server.io \
        --recv-keys "58D6AD46BC509C6181A22C5F9A6F0EB91222CCA0" \
    && gpg \
        --batch \
        --verify /opt/AdGuardHome/AdGuardHome.sig /opt/AdGuardHome/AdGuardHome \
    && { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
    \
    && chmod a+x /opt/AdGuardHome/AdGuardHome \
    \
    && apk del --no-cache --purge .build-dependencies \
    && rm -fr \
        "$GNUPGHOME" \
        /etc/nginx \
        /tmp/*

 # Copy root filesystem
COPY rootfs /

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="AdGuard Home" \
    io.hass.description="Network-wide ads & trackers blocking DNS server" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.title="AdGuard Home" \
    org.opencontainers.image.description="Network-wide ads & trackers blocking DNS server" \
    org.opencontainers.image.vendor="Home Assistant Community Add-ons" \
    org.opencontainers.image.authors="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://addons.community" \
    org.opencontainers.image.source="https://github.com/hassio-addons/addon-adguard-home" \
    org.opencontainers.image.documentation="https://github.com/hassio-addons/addon-adguard-home/blob/master/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
