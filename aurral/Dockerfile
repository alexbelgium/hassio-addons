# ==============================================================
# Home Assistant Add-on: Aurral
# Wraps the upstream ghcr.io/lklynet/aurral image.
# ==============================================================
ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
    io.hass.name="Aurral" \
    io.hass.description="Self-hosted music discovery, requests, and playback" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="petruknw"

# Aurral 3 reads LIBRARY_FOLDER; DOWNLOAD_FOLDER is a deprecated alias.
# The entrypoint replaces this default with the download_folder option
ENV LIBRARY_FOLDER=/share/aurral/downloads

# The add-on keeps its database in /config/data. Aurral 3 only looks in /config
# unless told otherwise, and exits when it finds the database in the old
# /app/backend/data path, so point it at /config/data explicitly. The entrypoint
# keeps using /config when the database is already there
ENV AURRAL_DATA_DIR=/config/data

# Browse folders defaults to /data, which in an add-on is its private storage.
# Offer the folders that hold music instead
ENV FILE_BROWSE_ROOTS=/media,/share

COPY rootfs /

RUN chmod a+x /usr/local/bin/docker-entrypoint.sh

# Same init and command as the upstream image. tini reaps the yt-dlp and ffmpeg
# child processes and passes the stop signal on to node
ENTRYPOINT ["tini", "-s", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "--max-semi-space-size=4", "backend/server.ts"]
