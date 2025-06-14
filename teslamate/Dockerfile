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

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

# Add additional tools
RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
    inotify-tools \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

##################
# 3 Finalize    #
##################

# Add rootfs
COPY rootfs/ /

# Volumes
VOLUME ["/data", "/config"]

# Healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD wget -q --no-check-certificate --spider http://127.0.0.1:4000/ || exit 1

# Labels
LABEL \
    io.hass.name="TeslaMate" \
    io.hass.description="A powerful data logger for Tesla vehicles" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium" \
    url="https://github.com/alexbelgium/hassio-addons"

# Environment
ENV \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    LANG=C.UTF-8 \
    TERM=xterm-256color \
    DISABLE_AUTHENTICATION=true

# Ports
EXPOSE 4000/tcp

# Entrypoint
ENTRYPOINT ["/usr/bin/with-contenv", "/usr/bin/run.sh"]
COPY rootfs /

# Create required directories
RUN mkdir -p /data

ENTRYPOINT ["/init"]

CMD ["/usr/bin/run.sh"]

LABEL \
    io.hass.name="TeslaMate" \
    io.hass.description="A powerful data logger for Tesla vehicles" \
    io.hass.type="addon" \
    io.hass.version=${TESLAMATE_VERSION}
