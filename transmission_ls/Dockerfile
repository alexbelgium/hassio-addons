ARG BUILD_FROM
FROM $BUILD_FROM

# Copy root filesystem
COPY rootfs /

# MOFIFY DATA PATH
RUN sed -i "s|config|share/transmission|g" /etc/services.d/transmission/run

VOLUME [ "/data" ]
