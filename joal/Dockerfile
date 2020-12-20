ARG BUILD_FROM
FROM $BUILD_FROM


RUN mkdir -p /joal \
    &&  curl -L -s \
        "https://github.com/anthonyraymond/joal/releases/download/2.1.24/joal.tar.gz" \
        | tar zxvf - -C /joal \
    && chown -R $(id -u):$(id -g) /joal \
    && rm -fr \
        /tmp/*

VOLUME /data
        
CMD [ "--joal-conf=/joal" ]
VOLUME [ "/data" ]
