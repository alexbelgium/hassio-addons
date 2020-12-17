ARG BUILD_FROM
FROM $BUILD_FROM

# Copy root filesystem
COPY rootfs /

# MOFIFY DATA PATH
RUN sed -i "s|config|share/transmission|g" /etc/services.d/transmission/run \
    && sed -i "s|config|share/transmission|g" /etc/cont-init.d/20-config

VOLUME [ "/data" ]