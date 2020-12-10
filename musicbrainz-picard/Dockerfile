ARG BUILD_FROM=hassioaddons/base:8.0.1
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Update and Add musicbrainz Repo
RUN apt-get update && \
    apt-get -y --no-install-recommends install software-properties-common && \
    rm -rf /var/lib/apt/lists/* && \
    add-apt-repository ppa:musicbrainz-developers/stable

# Install musicbrainz & fpcalc (provided by Chromaprint) 
RUN apt-get update && \
    apt-get -y --no-install-recommends install picard libchromaprint-tools && \
    rm -rf /var/lib/apt/lists/*

# Locale
ENV LANG=es_ES.UTF-8
RUN apt-get update && \
    apt-get -y --no-install-recommends install locales && \
    locale-gen en_US.UTF-8 && \
    locale-gen es_ES.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

# Define Run
ENV APP_NAME="musicbrainz"
COPY startapp.sh /startapp.sh

RUN /startapp.sh
