ARG BUILD_FROM
ARG BUILD_VERSION

FROM ${BUILD_FROM}${BUILD_VERSION}

# Add bashio
#RUN apk add --no-cache \
#    curl \
#    jq \
#    && curl -J -L -o /tmp/bashio.tar.gz \
#    "https://github.com/hassio-addons/bashio/archive/v0.7.1.tar.gz" \
#    && mkdir /tmp/bashio \
#    && tar zxvf \
#    /tmp/bashio.tar.gz \
#    --strip 1 -C /tmp/bashio \
#    \
#    && mv /tmp/bashio/lib /usr/lib/bashio \
#    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
#    && rm -fr /tmp/bashio.tar.gz

# Copy root filesystem
# COPY rootfs /

# MOFIFY DATA PATH
# RUN sed -i "s|/data/papermerge|/papermerge|g" /etc/services.d/papermerge/run \
#    && sed -i "s|/data/papermerge|/papermerge|g" /etc/cont-init.d/30-config

VOLUME [ "/data" ]
