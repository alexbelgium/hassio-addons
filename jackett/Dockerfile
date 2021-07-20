ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="0.18.455"
FROM ${BUILD_FROM}${BUILD_UPSTREAM}


RUN curl -J -L -o /tmp/bashio.tar.gz \
    "https://github.com/hassio-addons/bashio/archive/v0.13.0.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
    /tmp/bashio.tar.gz \
    --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr /tmp/bashio.tar.gz 

# use /data instead of /config for hass.io environment
RUN sed -i "s|/config|/config/jackett|g" /etc/services.d/jackett/run \
    && sed -i "s|/config|/config/jackett|g" /etc/cont-init.d/30-config \
    \
    # Allow UID and GID setting
    && sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser

# copy local files
COPY root/ /
