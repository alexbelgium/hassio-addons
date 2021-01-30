ARG BUILD_FROM
FROM $BUILD_FROM

VOLUME [ "/data" ]

#Install last version https://github.com/dvershinin/lastversion
RUN \
    apk add --no-cache git \
    && pip install --upgrade pip \
    && pip install lastversion

# Copy root filesystem
COPY rootfs /

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
