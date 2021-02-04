ARG BUILD_VERSION

FROM coderaiser/cloudcmd:$BUILD_VERSION

COPY run.sh /

RUN chmod 777 /run.sh

ENTRYPOINT [ "/run.sh" ]

VOLUME [ "/data" ]
