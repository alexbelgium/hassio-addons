ARG BUILD_VERSION
ARG BUILD_UPSTREAM="15.9.1"
FROM coderaiser/cloudcmd:$BUILD_UPSTREAM

COPY run.sh /

RUN chmod 777 /run.sh

ENTRYPOINT [ "/run.sh" ]

VOLUME [ "/data" ]
