ARG BUILD_VERSION
FROM "hurlenko/filebrowser:v$BUILD_VERSION"

RUN apk add --no-cache \
    curl \
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
    && rm -fr /tmp/bashio.tar.gz\
	\
	&& mkdir -p -m 777 /config/filebrowser	

VOLUME [ "/data" ]

COPY run.sh /
RUN chmod 777 /run.sh
ENTRYPOINT [ "run.sh" ]
CMD [ "" ] 
