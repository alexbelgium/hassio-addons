ARG BUILD_FROM
ARG BUILD_VERSION
FROM $BUILD_FROM

#Install bashio
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

#Install Joal
RUN mkdir -p /joal \
    &&  curl -L -s \
    "https://github.com/anthonyraymond/joal/releases/download/${BUILD_VERSION}/joal.tar.gz" \
    | tar zxvf - -C /joal \
    && chown -R $(id -u):$(id -g) /joal

#Clean
RUN rm -fr \
    /tmp/* \
    /var/{cache,log}/* \
    /var/lib/apt/lists/*

COPY run.sh /
RUN chmod 777 /run.sh
ENTRYPOINT [ "/run.sh" ]

# CMD [ "--joal-conf=/joal" ]
VOLUME [ "/data" ]
