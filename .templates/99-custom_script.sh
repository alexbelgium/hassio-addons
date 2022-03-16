#!/bin/bash

CONFIGSOURCE=$(bashio::config "CONFIG_LOCATION")
CONFIGSOURCE="$(dirname "${CONFIGSOURCE}")"

if [ -f "$CONFIGSOURCE"/script.sh ]; then
  "$CONFIGSOURCE"./script.sh
fi
