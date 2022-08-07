#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
if [ -e "/PORTFILE" ]; then
    echo "Installing portainer..."
    BUILD_UPSTREAM=$(</PORTFILE)
    BUILD_ARCH=$(uname -m)

    echo "${BUILD_ARCH}"
    BUILD_ARCH=${BUILD_ARCH:-x86}

    if [[ "${BUILD_ARCH}" == *aarch64* ]]; then ARCH="arm64"; fi
    if [[ "${BUILD_ARCH}" == *armv8* ]]; then ARCH="arm64"; fi
    if [[ "${BUILD_ARCH}" == *arm64* ]]; then ARCH="arm64"; fi
    if [[ "${BUILD_ARCH}" == *armhf* ]]; then ARCH="arm"; fi
    if [[ "${BUILD_ARCH}" == *armv7* ]]; then ARCH="arm"; fi
    if [[ "${BUILD_ARCH}" == arm ]]; then ARCH="arm"; fi
    if [[ "${BUILD_ARCH}" == *x86* ]]; then ARCH="amd64"; fi

    curl -f -L -s -S \
        "https://github.com/portainer/portainer/releases/download/${BUILD_UPSTREAM}/portainer-${BUILD_UPSTREAM}-linux-${ARCH}.tar.gz" |
    tar zxvf - -C /opt/ >/dev/null
    echo "... success!"
fi
