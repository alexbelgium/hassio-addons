# syntax=docker/dockerfile:1
#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
# BirdNET-Go (OpenVINO/AMD64)#
#============================#
#           _.------.
#       _.-`    ('>.-`"""-.  
# '.--'`       _'`   _ .--.) 
#    -'         '-.-';`   `  
#    ' -      _.'  ``'--.    
#        '---`    .-'""``    
#               /`           
#=== Home Assistant Addon ===#
#
# AMD64-only, OpenVINO-enabled build of the BirdNET-Go add-on.
# The binary is compiled from the alexbelgium/birdnet-go fork with the
# OpenVINO inference backend enabled (openvino build tag). The OpenVINO
# 2026.2 runtime libraries are bundled in the image, enabling:
#   - Faster CPU inference on modern Intel CPUs (AVX-512/AMX)
#   - Intel iGPU inference when /dev/dri is passed from the host
#
# Before compiling, "merge-prs.sh" clones the fork, fast-forwards its main
# onto the tphakala/birdnet-go upstream and merges every OPEN, NON-DRAFT
# pull request on the fly. Home Assistant integration layers (2-6) are then
# applied on top and are byte-for-byte identical to the upstream variant.
#
# Build stages 0-1 mirror tphakala/birdnet-go's Docker/Dockerfile; if
# upstream changes its build (Go/Node/onnxruntime versions, task names)
# sync them here.

##########################################################
# 0  Prepare merged BirdNET-Go source tree (fork + PRs)  #
##########################################################

FROM alpine/git:latest AS birdnet-source
ARG BIRDNET_FORK=alexbelgium/birdnet-go
ARG BIRDNET_UPSTREAM=tphakala/birdnet-go
# BUILD_DATE changes on every CI run, busting this layer's cache so the fork is
# re-cloned and the open PRs are re-merged "on the fly" on every build.
ARG BUILD_DATE=unknown
RUN apk add --no-cache bash curl jq
COPY merge-prs.sh /usr/local/bin/merge-prs.sh
RUN chmod +x /usr/local/bin/merge-prs.sh && \
    echo "Build date marker: ${BUILD_DATE}" && \
    BIRDNET_FORK="${BIRDNET_FORK}" BIRDNET_UPSTREAM="${BIRDNET_UPSTREAM}" \
    /usr/local/bin/merge-prs.sh /birdnet-src

##########################################################
# 0b Download OpenVINO runtime libraries for amd64       #
##########################################################

FROM alpine:3 AS openvino-libs
ARG OPENVINO_BUILD=2026.2.0.21903.52ddc073857
ARG OPENVINO_RELEASE=2026.2

# Download the x86_64 OpenVINO runtime package and extract runtime/lib/intel64.
# The same build id is used for the C API headers downloaded during compilation
# (see Taskfile.yml OPENVINO_BUILD), ensuring header/runtime version parity.
# We use the arm64 package for headers (arch-independent C declarations) but the
# x86_64 package here for the actual runtime .so files.
#
# OpenVINO links against its own bundled oneTBB (libtbb.so.12, libtbbmalloc*),
# which does NOT live in runtime/lib/intel64 but in runtime/3rdparty/tbb/lib.
# It must be bundled too, otherwise dlopen("libopenvino_c.so") fails at runtime
# with "libtbb.so.12: cannot open shared object file: No such file or directory"
# and the OpenVINO backend silently falls back / GPU planning treats the device
# as unavailable.
RUN apk add --no-cache curl && \
    mkdir -p /openvino && \
    curl -fsSL \
        "https://storage.openvinotoolkit.org/repositories/openvino/packages/${OPENVINO_RELEASE}/linux/openvino_toolkit_ubuntu22_${OPENVINO_BUILD}_x86_64.tgz" \
        -o /tmp/openvino.tgz && \
    tar -xzf /tmp/openvino.tgz -C /tmp/ --strip-components=1 && \
    cd /tmp/runtime/lib/intel64 && \
    tar -cf - . | tar -xf - -C /openvino/ && \
    # Bundle OpenVINO's own oneTBB runtime (preserving symlinks with cp -a).
    # Search the whole 3rdparty tree so the copy survives minor layout changes
    # between OpenVINO releases. Fail the build loudly if libtbb is missing,
    # since the runtime is unusable without it.
    find /tmp/runtime/3rdparty -name 'libtbb*.so*' -exec cp -a {} /openvino/ \; && \
    if ! ls /openvino/libtbb.so.12* >/dev/null 2>&1; then \
        echo "ERROR: libtbb.so.12 not found in OpenVINO package 3rdparty/tbb" >&2; \
        exit 1; \
    fi && \
    rm -rf /tmp/openvino.tgz /tmp/runtime /tmp/tools /tmp/python \
           /tmp/samples /tmp/install_dependencies 2>/dev/null || true

#########################################################################
# 1a Build environment (mirrors tphakala/birdnet-go Docker/Dockerfile)  #
#########################################################################

FROM --platform=$BUILDPLATFORM golang:1.26-trixie AS buildenv
ARG BUILD_VERSION
ENV BUILD_VERSION=${BUILD_VERSION:-unknown}

# Install Task and other dependencies
RUN apt-get update -q && apt-get install -q -y \
    curl \
    git \
    sudo \
    zip \
    gcc-aarch64-linux-gnu && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js v24 from NodeSource
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Task
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# Create dev-user for building
RUN groupadd --gid 10001 dev-user && \
    useradd --uid 10001 --gid dev-user --shell /bin/bash --create-home dev-user && \
    usermod -aG sudo dev-user && \
    usermod -aG audio dev-user && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /home/dev-user/src && \
    mkdir -p /home/dev-user/lib && \
    mkdir -p /home/dev-user/.cache && \
    mkdir -p /home/dev-user/.npm && \
    chown -R dev-user:dev-user /home/dev-user

USER dev-user
WORKDIR /home/dev-user/src/BirdNET-Go

# Bring in the merged source tree (fork main + upstream sync + open PRs)
COPY --from=birdnet-source --chown=dev-user /birdnet-src ./

# Pre-build frontend once in the shared buildenv stage
ENV PUPPETEER_SKIP_DOWNLOAD=true
RUN task frontend-build

##################
# 1b Build stage #
##################

FROM --platform=$BUILDPLATFORM buildenv AS build
ARG BUILD_VERSION
ENV BUILD_VERSION=${BUILD_VERSION:-unknown}
ARG ONNXRUNTIME_VERSION=1.25.1

# Download ONNX Runtime for amd64 (x64)
RUN echo "Downloading ONNX Runtime ${ONNXRUNTIME_VERSION} for x64" && \
    curl -fsSL "https://github.com/microsoft/onnxruntime/releases/download/v${ONNXRUNTIME_VERSION}/onnxruntime-linux-x64-${ONNXRUNTIME_VERSION}.tgz" \
        -o /tmp/onnxruntime.tgz && \
    mkdir -p /tmp/onnxruntime && \
    tar -xzf /tmp/onnxruntime.tgz -C /tmp/onnxruntime --strip-components=1 && \
    cp /tmp/onnxruntime/lib/libonnxruntime*.so* /home/dev-user/lib/ && \
    rm -rf /tmp/onnxruntime /tmp/onnxruntime.tgz

# Build BirdNET-Go for amd64 with OpenVINO enabled.
# OPENVINO=true compiles in the openvino build tag, enabling the OpenVINO
# inference backend (dlopen'd at runtime; falls back to ONNX Runtime when
# libopenvino_c.so is absent). The noembed_linux_amd64 task defaults to
# OPENVINO=true anyway; we make it explicit here for clarity.
RUN --mount=type=cache,target=/go/pkg/mod,uid=10001,gid=10001 \
    --mount=type=cache,target=/home/dev-user/.cache/go-build,uid=10001,gid=10001 \
    task check-tensorflow && \
    echo "Building amd64 with OpenVINO enabled, BUILD_VERSION=${BUILD_VERSION}" && \
    BUILD_VERSION="${BUILD_VERSION}" DOCKER_LIB_DIR=/home/dev-user/lib task noembed_linux_amd64 OPENVINO=true

#####################################################
# 1c BirdNET-Go runtime base (mirrors upstream)     #
#####################################################

FROM debian:trixie-slim AS birdnet-runtime

# Copy TFLite model files (amd64 uses TFLite; OpenVINO reads them via its
# TFLite frontend plugin bundled in the OpenVINO runtime below)
RUN mkdir -p /models
COPY --from=build /home/dev-user/src/BirdNET-Go/internal/classifier/data/*.tflite /models/
RUN chmod -R a+r /models/*.tflite 2>/dev/null || true && \
    chmod a+x /models

# Install ALSA library, SOX for audio processing, and system utilities.
# ocl-icd-libopencl1 provides the OpenCL ICD loader; combined with
# /dev/dri passthrough from the host it enables Intel iGPU inference.
RUN apt-get update -q && apt-get install -q -y --no-install-recommends \
    adduser \
    ca-certificates \
    libasound2 \
    ffmpeg \
    sox \
    libsox-fmt-mp3 \
    procps \
    iproute2 \
    net-tools \
    curl \
    wget \
    nano \
    vim \
    less \
    tzdata \
    tzdata-legacy \
    jq \
    strace \
    lsof \
    bash-completion \
    gosu \
    ocl-icd-libopencl1 \
    && rm -rf /var/lib/apt/lists/*

# Copy TensorFlow Lite library from build stage
COPY --from=build /home/dev-user/lib/libtensorflowlite_c.so* /usr/lib/

# Copy ONNX Runtime libraries from build stage
COPY --from=build /home/dev-user/lib/libonnxruntime*.so* /usr/lib/

# Copy OpenVINO runtime libraries (libopenvino_c.so, CPU/GPU plugins,
# TFLite frontend, plugins.xml, bundled oneTBB libtbb.so.12, etc.) into a
# dedicated directory and register it with ldconfig so both
# dlopen("libopenvino_c.so") and its libtbb.so.12 dependency resolve.
# plugins.xml is co-located with libopenvino.so so device plugin
# discovery works without additional environment variables.
COPY --from=openvino-libs /openvino/ /usr/lib/openvino/
RUN echo "/usr/lib/openvino" > /etc/ld.so.conf.d/openvino.conf && ldconfig

# Include reset_auth tool from build stage
COPY --from=build /home/dev-user/src/BirdNET-Go/reset_auth.sh /usr/bin/
RUN chmod +x /usr/bin/reset_auth.sh

# Add entrypoint and startup wrapper scripts from build stage
COPY --from=build /home/dev-user/src/BirdNET-Go/Docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
COPY --from=build /home/dev-user/src/BirdNET-Go/Docker/startup-wrapper.sh /usr/bin/
RUN chmod +x /usr/bin/startup-wrapper.sh

# Create config and data directories with proper permissions for rootless compatibility
RUN mkdir -p /config /data/clips /data/models && \
    chmod 777 /config /data /data/clips /data/models

# Install the freshly built BirdNET-Go binary
COPY --from=build /home/dev-user/src/BirdNET-Go/bin /usr/bin/

# Enable openvino
ARG NEO_VERSION=26.22.38646.4
ARG IGC_VERSION=2.36.3+21719
RUN groupadd -g 109 render || true && \
    usermod -aG render root && \
    \
    apt-get update -q && apt-get install -q -y --no-install-recommends wget ocl-icd-libopencl1 libdrm2 libdrm-intel1 && \
    mkdir -p /tmp/neo && cd /tmp/neo && \
    wget -q https://github.com/intel/intel-graphics-compiler/releases/download/v2.36.3/intel-igc-core-2_${IGC_VERSION}_amd64.deb \
    https://github.com/intel/intel-graphics-compiler/releases/download/v2.36.3/intel-igc-opencl-2_${IGC_VERSION}_amd64.deb \
    https://github.com/intel/compute-runtime/releases/download/${NEO_VERSION}/intel-opencl-icd_${NEO_VERSION}-0_amd64.deb \
    https://github.com/intel/compute-runtime/releases/download/${NEO_VERSION}/libigdgmm12_22.10.0_amd64.deb \
    https://github.com/intel/compute-runtime/releases/download/${NEO_VERSION}/libze-intel-gpu1_${NEO_VERSION}-0_amd64.deb && \
    dpkg -i *.deb && \
    rm -rf /tmp/neo && \
    rm -rf /var/lib/apt/lists/*

#============================================================================#
# From here on, the Home Assistant integration layers are identical to the   #
# standard alexbelgium/birdnet-go add-on (which builds FROM the prebuilt    #
# upstream image). The only difference above is that the base is compiled    #
# from the fork + open PRs with OpenVINO enabled.                           #
#============================================================================#

##################
# 2 Modify Image #
##################

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /
RUN find . -type f \( -name "*.sh" -o -name "run" -o -name "finish" \) -print -exec chmod +x {} \;

# Silence "chmod: Read-only file system" noise from upstream entrypoint:
# Home Assistant mounts /dev/snd read-only, so the chmod is a no-op and the
# stderr output is just noise. The "|| true" already absorbs the exit code.
# Warn (without failing the build) if the upstream pattern drifts so we notice
# in CI logs and can update the patch.
RUN if [ -f /usr/bin/entrypoint.sh ]; then \
        if grep -q 'chmod -R a+rw /dev/snd || true' /usr/bin/entrypoint.sh; then \
            sed -i 's#chmod -R a+rw /dev/snd || true#chmod -R a+rw /dev/snd 2>/dev/null || true#' /usr/bin/entrypoint.sh; \
        else \
            echo "WARN: upstream entrypoint.sh /dev/snd chmod pattern not found; nightly drift?" >&2; \
        fi; \
    fi

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES="00-local_mounts.sh 00-smb_mounts.sh"

# Automatic modules download
COPY ha_automodules.sh /ha_automodules.sh
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="alsa-utils libasound2-plugins mariadb-client nginx yq"

# Automatic apps & bashio
COPY ha_autoapps.sh /ha_autoapps.sh
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Add entrypoint
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
COPY ha_entrypoint.sh /ha_entrypoint.sh
RUN chmod 777 /ha_entrypoint.sh

# Install bashio
COPY bashio-standalone.sh /usr/local/lib/bashio-standalone.sh
RUN chmod 0755 /usr/local/lib/bashio-standalone.sh

# Avoid config.yaml interference
RUN sed -i "s|config.yaml|config_env.yaml|g" /etc/cont-init.d/01-config_yaml.sh
ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "/ha_entrypoint.sh" ]
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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
