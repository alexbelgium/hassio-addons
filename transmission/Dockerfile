#ARG BUILD_FROM
ARG BUILD_VERSION
#FROM $BUILD_FROM
ARG BUILD_ARCH
if [ $BUILD_ARCH = "armv7" ]; then
    ARG BUILD_ARCH="arm32v7"
  elif [ $BUILD_ARCH = "armhf" ]; then
    ARG BUILD_ARCH="arm32v7"
  elif [ $BUILD_ARCH = "aarch64" ]; then
    ARG BUILD_ARCH="arm64v8"
  elif [ $BUILD_ARCH = "amd64" ]; then
    ARG BUILD_ARCH="amd64"
fi

FROM linuxserver/transmission:${BUILD_ARCH}-${BUILD_VERSION}

# Add bashio
RUN apk add --no-cache \
    curl \
    jq \
    && curl -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/v0.7.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio

# Copy root filesystem
COPY rootfs /

# MOFIFY DATA PATH
RUN sed -i "s|config|share/transmission|g" /etc/services.d/transmission/run \
    && sed -i "s|config|share/transmission|g" /etc/cont-init.d/20-config

VOLUME [ "/data" ]
