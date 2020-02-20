ARG BUILD_FROM
# hadolint ignore=DL3006
FROM $BUILD_FROM

RUN sed -i "s|/config|/emby|g" /etc/services.d/emby/run \
    && sed -i "s|/config|/emby|g" /etc/cont-init.d/30-config 

RUN cat /etc/services.d/emby/run

# copy local files
COPY root/ /

