ARG BUILD_FROM
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy root filesystem
COPY rootfs /

# Setup base
RUN \
    apk add --no-cache \
        coreutils=9.5-r2 \
        openssl=3.3.3-r0 \
        tor=0.4.8.14-r1 \
        go=1.23.6-r0 \
        git=2.47.2-r0 \
        ca-certificates=20241121-r1 \
        libcap=2.71-r0

# Download pluggable-transports sources
WORKDIR /go
ARG OBFS_VERSION=obfs4proxy-0.0.14
ARG SNOWFLAKE_VERSION=v2.10.1
ARG WEBTUNNEL_VERSION=v0.0.2
RUN git clone -b ${OBFS_VERSION} --single-branch --depth 1 https://github.com/Yawning/obfs4.git \
        && git clone -b ${SNOWFLAKE_VERSION} --single-branch --depth 1 https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake.git \
        && git clone -b ${WEBTUNNEL_VERSION} --single-branch --depth 1 https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/webtunnel.git

# Build obfs4proxy
WORKDIR /go/obfs4
RUN go build -o /usr/local/bin/obfs4proxy ./obfs4proxy

# Build snowflake
WORKDIR /go/snowflake/client
RUN go get \
    && go build -ldflags '-extldflags "-static" -w -s' -o /usr/local/bin/snowflake

# Build webtunnel
WORKDIR /go/webtunnel/main/client
RUN go get \
    && go build -ldflags="-s -w" -o /usr/local/bin/webtunnel

# Clean up after build
WORKDIR /
RUN rm -rf /go

# Give transports clients the capability to bind privileged port.
RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/obfs4proxy \
    && setcap 'cap_net_bind_service=+ep'  /usr/local/bin/snowflake \
    && setcap 'cap_net_bind_service=+ep'  /usr/local/bin/webtunnel

HEALTHCHECK \
    --start-period=60m \
    --interval=60s \
    --timeout=30s \
    CMD curl \
        --silent \
        --location \
        --socks5-hostname localhost:9050 \
        https://check.torproject.org/?lang=en_US \
        | grep -qm1 Congratulations

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Community Add-ons" \
    org.opencontainers.image.authors="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://addons.community" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
