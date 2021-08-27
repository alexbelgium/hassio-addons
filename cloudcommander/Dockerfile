ARG BUILD_VERSION
FROM coderaiser/cloudcmd:latest
ARG BASHIO_VERSION=0.13.1

RUN \
    ################
    # Install apps #
    ################
    apt-get clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        jq \
        cifs-utils \    
        keyutils \
        samba \
        nginx \
    && apt-get clean \
    \
    ##################
    # Install bashio #
    ##################
    && mkdir -p /tmp/bashio \
    && curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    | tar -xzf - --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio \
    \
    /var/{cache,log}/* \
    /var/lib/apt/lists/*

# Copy root filesystem
COPY rootfs / 

RUN \
    ###############
    # Permissions #
    ###############
    chmod 777 /run.sh

ENTRYPOINT [ "/run.sh" ]

VOLUME [ "/data" ]
