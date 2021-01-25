ARG BUILD_FROM
FROM $BUILD_FROM

VOLUME [ "/data" ]

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG BUILD_VERSION

RUN \
#Install bashio
    apt-get update \
    && apt-get install -y --no-install-recommends \
    wget \
    jq \
    && curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v0.10.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
    /tmp/bashio.tar.gz \
    --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    \
#Install Joal
    # && curl -s -L -o /tmp/joal.tar.gz "https://github.com/anthonyraymond/joal/releases/download/2.1.24/joal.tar.gz" \
    && wget -O /tmp/joal.tar.gz "https://github.com/anthonyraymond/joal/releases/download/$BUILD_VERSION/joal.tar.gz" \
    && mkdir -p /data/joal \
    && tar zxvf /tmp/joal.tar.gz -C /data/joal \
    && chown -R $(id -u):$(id -g) /data/joal \
    && rm /data/joal/jack-of* \
#Clean
    && rm -fr \
    /tmp/* \
    /var/{cache,log}/* \
    /var/lib/apt/lists/*

COPY run.sh /
RUN chmod 777 /run.sh
ENTRYPOINT [ "/run.sh" ]
