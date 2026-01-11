#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

EXTENSIONS_DIR="${CHROME_EXTENSIONS_DIR:-/usr/src/chrome/extensions}"

bashio::log.info "Refreshing Chromium extensions in ${EXTENSIONS_DIR}"

mkdir -p "${EXTENSIONS_DIR}"

download_extension() {
  local name="$1"
  local extension_id="$2"
  local crx_path

  crx_path="$(mktemp)"
  curl -fsSL "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=120.0&acceptformat=crx2,crx3&x=id%3D${extension_id}%26installsource%3Dondemand%26uc" \
    -o "${crx_path}"
  rm -rf "${EXTENSIONS_DIR:?}/${name}"
  mkdir -p "${EXTENSIONS_DIR}/${name}"
  unzip -q "${crx_path}" -d "${EXTENSIONS_DIR}/${name}"
  rm -f "${crx_path}"
}

download_extension "i-dont-care-about-cookies" "fllaojicojecljbmefodhfapmkghcbnh"
download_extension "ublock-origin" "cjpalhdlnbpafiamejdnhcphjbkeiagm"

if id chrome &>/dev/null; then
  chown -R chrome:chrome "${EXTENSIONS_DIR}"
fi
