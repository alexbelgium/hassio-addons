ARG BUILD_FROM
# hadolint ignore=DL3006
FROM $BUILD_FROM

RUN apk add --no-cache \
        jq=1.6-r1 \
    && curl -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/v0.7.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr /tmp/* 

# fix folders for hassio environment
RUN sed -i "s|/config/keys/cert.crt|/ssl/fullchain.pem|g" /defaults/default && \
    sed -i "s|/config/keys/cert.key|/ssl/privkey.pem|g" /defaults/default && \    
    sed -i "s|/config|/config/heimdall|g" /defaults/default && \
    sed -i "s|/config|/config/heimdall|g" /defaults/nginx.conf && \
    sed -i "s|/config/keys/cert.crt|/ssl/fullchain.pem|g" /etc/cont-init.d/* && \
    sed -i "s|/config/keys/cert.key|/ssl/privkey.pem|g" /etc/cont-init.d/* && \
    sed -i "s|/config/heimdall/keys|/ssl|g" /etc/cont-init.d/* && \    
    sed -i "s|/config|/config/heimdall|g" /etc/cont-init.d/* && \
    sed -i "s|/config|/config/heimdall|g" /etc/services.d/nginx/* && \
    sed -i "s|/config|/config/heimdall|g" /etc/logrotate.d/heimdall


# copy local files
COPY root/ /