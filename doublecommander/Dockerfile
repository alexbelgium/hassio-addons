ARG BUILD_FROM
FROM $BUILD_FROM

# MOFIFY DATA PATH
RUN sed -i "s|config|data|g" /defaults/autostart

VOLUME [ "/data" ]
