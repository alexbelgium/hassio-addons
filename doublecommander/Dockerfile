ARG BUILD_FROM
FROM $BUILD_FROM

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
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio

# copy local files
COPY root/ /

# MOFIFY DATA PATH
RUN sed -i "s|config|data|g" /defaults/autostart

VOLUME [ "/data" ]
