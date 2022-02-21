#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Allow OCR setting
OCRLANG="$(bashio::config "ocrlang")"
languageCount=$(echo "$OCRLANG" | tr -cd ',' | wc -c)
languageCount=$((languageCount+1))
bashio::log.info "Configuring ${languageCount} languages"

if [ -n "$OCRLANG" ]; then
    lineStart=$(sed -n '/OCR_LANGUAGES/=' /data/config/papermerge.conf.py)
    bashio::log.info "OCRLANG variable is set, processing the language packages"
    lineEnd=$(sed -n '/}/=' /data/config/papermerge.conf.py)
    sed -i "${lineStart},${lineEnd}d" /data/config/papermerge.conf.py

    bashio::log.info "Writing new configuration"
    echo "OCRLANG = {" >> /data/config/papermerge.conf.py

    languages=$(echo "$OCRLANG" | tr "," "\n")

    apt-get update >/dev/null

    i=0
    for language in $languages; do
        bashio::log.info "Processing language ${language}"
        if apt-cache show tesseract-ocr-"${language}" >/dev/null 2>&1; then
            bashio::log.info "Installing tesseract-ocr-${language}"
            apt-get install -yqq tesseract-ocr-"${language}" >/dev/null
            languageFullName=$(apt-cache show tesseract-ocr-"${language}" | grep -E '^(Description|Description-en):' | grep -oE '[^ ]+$')
            bashio::log.info "${language} identified as ${languageFullName}"
            i=$((i+1))
            if [[ $i -eq $languageCount ]]; then
                echo "  \"$language\" : \"$languageFullName\"" >> /data/config/papermerge.conf.py
            elif [[ $i -eq 1 ]]; then
                echo "  \"$language\" : \"$languageFullName\"," >> /data/config/papermerge.conf.py
                bashio::log.info "Setting default language to ${language}"
                sed -i "s/^OCR_DEFAULT_LANGUAGE = \"eng\"/OCR_DEFAULT_LANGUAGE = \"${language}\"/g" /data/config/papermerge.conf.py
            else
                echo "  \"$language\" : \"$languageFullName\"," >> /data/config/papermerge.conf.py
            fi
            bashio::log.info "... ${language} installed"
        else
            bashio::log.info "Package tesseract-ocr-${language} not found in the repository, skipping"
        fi
    done
    echo "}" >> /data/config/papermerge.conf.py
fi
