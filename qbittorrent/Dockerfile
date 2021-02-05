ARG BUILD_FROM
ARG BUILD_VERSION

FROM ${BUILD_FROM}${BUILD_VERSION}

# Remove fixed folders, allows connection to webUI
RUN sed '11,13d' /defaults/qBittorrent.conf \ 
    # Allow connection to webUI
    && echo 'WebUI\HostHeaderValidation=false' >> /defaults/qBittorrent.conf \
    && echo 'WebUI\LocalHostAuth=false' >> /defaults/qBittorrent.conf \
    && sed -i 's/admin/homeassistant/g' /defaults/qBittorrent.conf
      
# Copy root filesystem
COPY rootfs /

VOLUME [ "/data" "/config" ]
