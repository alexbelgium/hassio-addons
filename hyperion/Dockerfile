ARG BUILD_FROM=hassioaddons/debian-base
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

ARG BUILD_ARCH=amd64
ARG RELEASE

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		libjpeg62-turbo=1:1.5.2-2+b1 \
		libavahi-compat-libdnssd1=0.7-4+b1 \
		libdbus-1-3=1.12.20-0+deb10u1 \
		libqt5sql5=5.11.3+dfsg1-1+deb10u3 \
		libqt5serialport5=5.11.3-2 \
		libqt5network5=5.11.3+dfsg1-1+deb10u3 \
		libqt5widgets5=5.11.3+dfsg1-1+deb10u3 \
		libqt5gui5=5.11.3+dfsg1-1+deb10u3 \
		libqt5core5a=5.11.3+dfsg1-1+deb10u3 \
		libusb-1.0=2:1.0.22-2 \
		zlib1g-dev=1:1.2.11.dfsg-1 \
	&& if [[ "${BUILD_ARCH}" = "amd64" ]]; then ARCH="Linux-x86_64"; fi \
	&& if [[ "${BUILD_ARCH}" = "aarch64" ]]; then ARCH="Linux-aarch64"; fi \
    && curl -fsSL https://github.com/hyperion-project/hyperion.ng/releases/download/${RELEASE}/Hyperion-${RELEASE}-${ARCH}.deb > /tmp/Hyperion-${RELEASE}-${ARCH}.deb \
	&& dpkg -i /tmp/Hyperion-${RELEASE}-${ARCH}.deb \
	&& rm -fr \
        /tmp/* \
        /var/{cache,log}/* \
        /var/lib/apt/lists/*

# copy local files
COPY root/ /
