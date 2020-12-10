FROM jlesage/baseimage-gui:ubuntu-18.04

LABEL maintainer="carvajal.diego@gmail.com"

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
