ARG BUILD_FROM
# hadolint ignore=DL3006
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# copy local files
COPY root/ /

RUN sed -i "s|/config|/musicbrainz|g" /etc/services.d/server/run

