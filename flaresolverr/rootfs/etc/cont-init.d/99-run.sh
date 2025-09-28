#!/bin/bash
# shellcheck shell=bash
set +eu

echo "Warning - minimum configuration recommended: 2 CPU cores and 4 GB of memory. Otherwise the system may become unresponsive or crash."

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
