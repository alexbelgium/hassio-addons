#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

LAUNCHER="sudo -u abc php /data/config/www/nextcloud/occ" || bashio::log.info "/data/config/www/nextcloud/occ not found"
if ! bashio::fs.file_exists '/data/config/www/nextcloud/occ'; then
  LAUNCHER=$(find / -name "occ" -print -quit)
fi || bashio::log.info "occ not found"

# Make sure there is an Nextcloud installation
if [[ $($LAUNCHER -V) == *"not installed"* ]]; then
  bashio::log.warning "It seems there is no Nextcloud server installed. Please restart the addon after initialization of the user."
  exit 0
fi

# Install OCR if requested
if [ "$(bashio::config 'OCR')" = "true" ]; then
  # Install package
  if bashio::config.true 'OCR'; then

    # Get Full Text Search app for nextcloud
    echo "... installing apps : fulltextsearch"
    occ app:install files_fulltextsearch_tesseract &>/dev/null || true
    occ app:enable files_fulltextsearch_tesseract &>/dev/null || true

    echo "Installing OCR"
    apk add --quiet --no-cache tesseract-ocr || apk add --quiet --no-cache tesseract-ocr@community
    # Install additional language if requested
    if bashio::config.has_value 'OCRLANG'; then
      OCRLANG=$(bashio::config 'OCRLANG')
      for LANG in $(echo "$OCRLANG" | tr "," " "); do
        if [ "$LANG" != "eng" ]; then
          apk add --quiet --no-cache tesseract-ocr-data-"$LANG" || apk add --quiet --no-cache tesseract-ocr-data-"$LANG"@community
        fi
        bashio::log.info "OCR Language installed : $LANG" || bashio::log.fatal "Couldn't install OCR lang $LANG. Please check its format is conform"
        # Downloading trainer data
        cd /usr/share/tessdata || true
        rm -r "$LANG".traineddata &>/dev/null || true
        wget https://github.com/tesseract-ocr/tessdata/raw/main/"$LANG".traineddata &>/dev/null
      done
    fi
  elif [ "$(bashio::config 'OCR')" = "false" ]; then
    bashio::log.info 'Removing OCR'
    # Delete package
    apk del tesseract-ocr.* &>/dev/null || true
    # Remove app
    occ app:disable files_fulltextsearch_tesseract &>/dev/null || true
  fi
fi
