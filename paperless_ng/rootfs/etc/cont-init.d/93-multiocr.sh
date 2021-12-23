#!/usr/bin/with-contenv bashio

OCRLANG=$(bashio::config 'OCRLANG')
if [ -n "$OCRLANG" ]; then
  apt-get update &>/dev/null
  echo "OCRLANG variable is set, processing the language packages"
  for i in $(echo "$OCRLANG" | tr "," " " "+"); do
    if apt-cache show tesseract-ocr-"${i}" > /dev/null 2>&1; then
      echo "installing tesseract-ocr-${i}"
      apt-get install -y tesseract-ocr-"${i}"

            # Downloading trainer data
            # Downloading trainer data
        #    cd /usr/share/tessdata
        #    sudo rm -r $LANG.traineddata &>/dev/null || true
        #    wget https://github.com/tesseract-ocr/tessdata/raw/main/$LANG.traineddata &>/dev/null
    else
      echo "package tesseract-ocr-${i} not found in the repository, skipping"
    fi
    bashio::log.info "OCR Language installed : $i" || bashio::log.fatal "Couldn't install OCR lang $i. Please check its format is conform"
  done
fi
