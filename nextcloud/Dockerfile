ARG BUILD_FROM
ARG BUILD_VERSION

FROM ${BUILD_FROM}-${BUILD_VERSION}

ENV NEXTCLOUD_PATH="/data/config/www/nextcloud"

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Add OCR
# RUN apk add --no-cache \
#    tesseract-ocr \
#    tesseract-ocr-data-deu

# modify/copy files
RUN sed -i "s|data|share/nextcloud|g" /etc/cont-init.d/* \
    && sed -i "s|config|data/config|g" /etc/cont-init.d/* \
    && sed -i "s|data|share/nextcloud|g" /etc/services.d/nginx/* \
    && sed -i "s|config|data/config|g" /etc/services.d/nginx/*

COPY root/ /

RUN ["chmod", "+x", "/defaults/nextcloud-perms.sh"]

VOLUME ["/share", "/ssl", "/data", "/media"]
