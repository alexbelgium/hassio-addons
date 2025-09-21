#!/bin/bash
# shellcheck shell=bash
set +eu

echo "Warning - minimum configuration recommended: 2 CPU cores and 4 GB of memory. Otherwise the system may become unresponsive or crash."

fix_file="/etc/chromium.d/dev-shm"

if [ -f "${fix_file}" ]; then
    bashio::log.info "Patching Chromium shared memory helper for reliable startup"
    cat <<'PATCH' > "${fix_file}"
# shellcheck shell=sh
# Patched by alexbelgium/hassio-addons to avoid arithmetic errors with large values on some shells.
shm_avail=$(findmnt -bnr -o avail -T /dev/shm 2>/dev/null)

if python3 - "${shm_avail}" <<'PY'
import re
import sys

raw = sys.argv[1] if len(sys.argv) > 1 else ''
match = re.search(r'\d+', raw)
value = int(match.group(0)) if match else 0
LIMIT = 4080218931
sys.exit(0 if value < LIMIT else 1)
PY
then
    export CHROMIUM_FLAGS="${CHROMIUM_FLAGS} --disable-dev-shm-usage"
fi
PATCH
    chmod 0644 "${fix_file}"
fi

chromium_wrapper="/usr/bin/chromium"

if [[ -f "${chromium_wrapper}" ]]; then
  if [[ ! -x /bin/bash ]]; then
    bashio::log.warning "Chromium wrapper patch skipped: /bin/bash is not available."
  else
    if grep -q '^#!/bin/sh' "${chromium_wrapper}"; then
      if grep -q '==' "${chromium_wrapper}"; then
        bashio::log.info "Adjusting Chromium wrapper to use bash for compatibility with Chromium 140."
        sed -i '1s|/bin/sh|/bin/bash|' "${chromium_wrapper}"
      fi
    fi
  fi
fi

##############
# LAUNCH APP #
##############

exec /usr/bin/dumb-init -- python -u /app/flaresolverr.py
