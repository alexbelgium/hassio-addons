ARG BUILD_FROM
ARG BUILD_VERSION

FROM ${BUILD_FROM}-${BUILD_VERSION}

# Install bashio
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    jq \
    && curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v0.7.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
    /tmp/bashio.tar.gz \
    --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr \
    /tmp/* \
    /var/{cache,log}/* \
    /var/lib/apt/lists/*

# copy local files
COPY root/ /

# MOFIFY DATA PATH
RUN sed -i "s|config|data|g" /defaults/autostart

VOLUME [ "/data" ]
