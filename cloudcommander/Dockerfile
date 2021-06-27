ARG BUILD_VERSION
ARG BUILD_UPSTREAM="15.9.7"
FROM coderaiser/cloudcmd:$BUILD_UPSTREAM

COPY run.sh /

ARG BASHIO_VERSION=0.13.0

RUN \
    ################
    # Install apps #
    ################
    apt-get update \
    && apt-get install -y --no-install-recommends \
    jq \
    cifs-utils \
    keyutils \
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
    /var/lib/apt/lists/* \
    \
    ###############
    # Permissions #
    ###############
    && chmod 777 /run.sh

ENTRYPOINT [ "/run.sh" ]

VOLUME [ "/data" ]
