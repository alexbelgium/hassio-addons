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

# Use virtual environment for Node.js
ENV NODE_ENV=production

# Add additional tools
RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
    inotify-tools \
    wget \
    jq \
    nginx \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

##################
# 3 Install app #
##################

# Ensure data persistence
RUN \
    mkdir -p /app/data \
    && chown -R 1000:1000 /app/data

##################
# 4 Finalize    #
##################

# Add rootfs
COPY rootfs/ /

# Volumes
VOLUME ["/app/data"]

# Healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD wget -q --no-check-certificate --spider http://127.0.0.1:3001/ || exit 1

# Labels
LABEL \
    io.hass.name="Uptime Kuma" \
    io.hass.description="A modern uptime monitoring solution" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium" \
    url="https://github.com/alexbelgium/hassio-addons"

# Environment
ENV \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    LANG=C.UTF-8 \
    TERM=xterm-256color \
    UMASK=002

# Ports
EXPOSE 3001/tcp

# Entrypoint
ENTRYPOINT ["/usr/bin/with-contenv", "/usr/bin/run.sh"]
