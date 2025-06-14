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

ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}

##################
# 2 Modify Image #
##################

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

# Install requirements for add-on
RUN \
    apk add --no-cache \
    python3 \
    py3-pip \
    git \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    openssl-dev \
    cargo \
    && pip3 install --upgrade pip wheel setuptools

##################
# 3 Install App #
##################

# Clone the TeslaMate ABRP repository
WORKDIR /app
RUN git clone --depth 1 https://github.com/fetzu/teslamate-abrp . \
    && pip3 install --no-cache-dir -r requirements.txt \
    && rm -rf \
    /root/.cache \
    /root/.cargo \
    /tmp/*

##################
# 4 Finalize    #
##################

# Copy root filesystem
COPY rootfs/ /

# Volumes
VOLUME ["/data", "/config"]

# Labels
LABEL \
    io.hass.name="TeslaMate ABRP" \
    io.hass.description="A Better Route Planner integration for TeslaMate" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium" \
    url="https://github.com/alexbelgium/hassio-addons"

# Environment
ENV \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    LANG=C.UTF-8 \
    TERM=xterm-256color \
    PYTHONUNBUFFERED=1

# Entrypoint
ENTRYPOINT ["/init"]
