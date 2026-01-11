#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

EXTENSIONS_DIR="${CHROME_EXTENSIONS_DIR:-/usr/src/chrome/extensions}"
bashio::log.info "Refreshing Chromium extensions in ${EXTENSIONS_DIR}"

mkdir -p "${EXTENSIONS_DIR}"

download_extension() {
  local name="$1"
  local extension_id="$2"
  local crx_path rc

  crx_path="$(mktemp)"

  if ! curl -fsSL \
    "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=120.0&acceptformat=crx2,crx3&x=id%3D${extension_id}%26installsource%3Dondemand%26uc" \
    -o "${crx_path}"; then
    rm -f "${crx_path}"
    bashio::log.warning "Failed to download extension ${name}. Continuing without refresh."
    return 0
  fi

  rm -rf "${EXTENSIONS_DIR:?}/${name}"
  mkdir -p "${EXTENSIONS_DIR}/${name}"

  rc=0
  unzip -q "${crx_path}" -d "${EXTENSIONS_DIR}/${name}" || rc=$?
  rm -f "${crx_path}"

  # unzip may return 1 even though files extracted (common with CRX zip metadata)
  if [ "${rc}" -ne 0 ] && [ "${rc}" -ne 1 ]; then
    bashio::log.warning "Failed to unzip extension ${name} (rc=${rc}). Continuing."
    return 0
  fi

  return 0
}

download_extension "i-dont-care-about-cookies" "fllaojicojecljbmefodhfapmkghcbnh"
download_extension "ublock-origin" "cjpalhdlnbpafiamejdnhcphjbkeiagm"

if id chrome &>/dev/null; then
  chown -R chrome:chrome "${EXTENSIONS_DIR}"
fi
