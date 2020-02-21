ARG BUILD_FROM
# hadolint ignore=DL3006
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    \
    && apt-get install -y --no-install-recommends \
        jq=1.5+dfsg-2 \    
    \
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

RUN sed -i "s|/config/data|/share/jellyfin/data|g" /etc/services.d/jellyfin/run \
    && sed -i "s|/config/log|/share/jellyfin/log|g" /etc/services.d/jellyfin/run \
    && sed -i "s|/config/cache|/share/jellyfin/cache|g" /etc/services.d/jellyfin/run \
    && sed -i "s|/config|/config/jellyfin|g" /etc/services.d/jellyfin/run \
    && sed -i "s|/config/{log,data,cache}|/xxx/jellyfin|g" /etc/cont-init.d/30-config \
    && sed -i "s|/config|/config/jellyfin|g" /etc/cont-init.d/30-config \
    && sed -i "s|/xxx|/config|g" /etc/cont-init.d/30-config \
    && sed -i "s|/data|/share/jellyfin/data|g" /etc/cont-init.d/30-config

RUN cat /etc/services.d/jellyfin/run && cat /etc/cont-init.d/30-config

# copy local files
COPY root/ /
