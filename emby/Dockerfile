FROM linuxserver/emby:4.3.1.0-ls26

RUN sed -i "s|/config|/emby|g" /etc/services.d/emby/run \
    && sed -i "s|/config|/emby|g" /etc/cont-init.d/30-config 

RUN cat /etc/services.d/emby/run

# copy local files
COPY root/ /

