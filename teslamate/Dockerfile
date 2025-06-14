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
ARG TESLAMATE_VERSION
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

# Install required packages
RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        inotify-tools \
        wget \
        ca-certificates \
        curl \
        git \
        gnupg2 \
        nginx \
    && curl -fsSL https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | gpg --dearmor -o /usr/share/keyrings/erlang.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/erlang.gpg] https://packages.erlang-solutions.com/ubuntu focal contrib' > /etc/apt/sources.list.d/erlang.list \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs \
        elixir \
        erlang-dev \
        erlang-nox \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

##################
# 3 Install App #
##################

# Download TeslaMate
WORKDIR /opt
RUN git clone --depth 1 --branch ${TESLAMATE_VERSION} \
    https://github.com/teslamate-org/teslamate.git

# Build application
WORKDIR /opt/teslamate
RUN \
    # Install Elixir dependencies
    mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && MIX_ENV=prod mix compile \
    \
    # Install & build frontend
    && cd assets \
    && npm ci --no-audit \
    && npm run deploy \
    \
    # Build Phoenix assets
    && cd .. \
    && mix phx.digest \
    \
    # Create release
    && MIX_ENV=prod mix release

##################
# 4 Finalize    #
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
    DISABLE_AUTHENTICATION=true \
    PATH="/opt/teslamate/bin:$PATH"

# Ports
EXPOSE 4000/tcp

# Entrypoint
ENTRYPOINT ["/init"]

CMD ["/usr/bin/run.sh"]

LABEL \
    io.hass.name="TeslaMate" \
    io.hass.description="A powerful data logger for Tesla vehicles" \
    io.hass.type="addon" \
    io.hass.version=${TESLAMATE_VERSION}
