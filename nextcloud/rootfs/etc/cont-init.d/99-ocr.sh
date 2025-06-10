#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Runs only after initialization done
# shellcheck disable=SC2128
if [ ! -f /app/www/public/occ ]; then cp /etc/cont-init.d/"$(basename "${BASH_SOURCE}")" /scripts/ && exit 0; fi

# Only execute if installed
if [ -f /notinstalled ]; then exit 0; fi

# Install OCR if requested
if [ "$(bashio::config 'OCR')" = "true" ]; then
	# Install package
	if bashio::config.true 'OCR'; then

		# Get Full Text Search app for nextcloud
		echo "... installing apps : fulltextsearch"
		occ app:install files_fulltextsearch_tesseract &>/dev/null || true
		occ app:enable files_fulltextsearch_tesseract &>/dev/null || true

		echo "Installing OCR"
		apk add --quiet --no-cache ocrmypdf
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
