#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

OCRLANG=$(bashio::config 'OCRLANG')
if [ -n "$OCRLANG" ]; then
    apt-get update &>/dev/null
    echo "OCRLANG variable is set, processing the language packages"
    for i in ${OCRLANG//,/ }; do
        if apt-cache show tesseract-ocr-"${i}" >/dev/null 2>&1; then
            apt-get install -yq tesseract-ocr-"${i}"
            bashio::log.info "OCR Language installed : $i" || bashio::log.fatal "Couldn't install OCR lang $i. Please check its format is conform"
        else
            echo "package tesseract-ocr-${i} not found in the repository, skipping"
        fi
    done
fi
