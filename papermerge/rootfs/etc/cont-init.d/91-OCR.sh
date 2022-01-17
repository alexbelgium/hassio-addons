#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Allow OCR setting
OCRLANG="$(bashio::config "ocrlang")"

if [ -n "$OCRLANG" ]; then
  LINE=$(sed -n '/OCR_LANGUAGES/=' /data/config/papermerge.conf.py)
  bashio::log.info "OCRLANG variable is set, processing the language packages"
  apt-get update >/dev/null
  for i in $(echo "$OCRLANG" | tr "," " "); do
    if apt-cache show tesseract-ocr-"${i}" >/dev/null 2>&1; then
      echo "installing tesseract-ocr-${i}" >/dev/null
      apt-get install -yqq tesseract-ocr-"${i}" >/dev/null
    else
      echo "package tesseract-ocr-${i} not found in the repository, skipping"
    fi
    sed -i "$LINE a   \"${i}\": \"${i}\"," /data/config/papermerge.conf.py
    bashio::log.info "... ${i} installed"
  done
fi
