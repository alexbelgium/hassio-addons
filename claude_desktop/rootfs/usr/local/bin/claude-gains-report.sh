#!/usr/bin/with-contenv bashio
# Hourly RTK + Headroom + TokenSave token-savings snapshot for the add-on log.
# Invoked by cron (see /defaults/crontabs/root); stdout is redirected to /proc/1/fd/1.
# Each tool is reported independently so enabling Headroom cannot hide RTK or TokenSave data.
# with-contenv supplies the configured persistent HOME.
export NO_COLOR=1
export PATH="/lsiopy/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

if ! bashio::config.true 'enable_tools_health_report'; then
    exit 0
fi

rtk_enabled=false
headroom_enabled=false
tokensave_enabled=false

if bashio::config.true 'install_rtk' && command -v rtk > /dev/null 2>&1; then
    rtk_enabled=true
fi
if bashio::config.true 'install_headroom' && command -v headroom > /dev/null 2>&1; then
    headroom_enabled=true
fi
if bashio::config.true 'install_tokensave' && command -v tokensave > /dev/null 2>&1; then
    tokensave_enabled=true
fi

if ! $rtk_enabled && ! $headroom_enabled && ! $tokensave_enabled; then
    exit 0
fi

echo "===== claude tools report $(date '+%Y-%m-%d %H:%M:%S') ====="
if $headroom_enabled; then
    echo "--- headroom savings ---"
    headroom savings 2>&1 || echo "[warn] headroom savings failed"
fi
if $rtk_enabled; then
    echo "--- rtk gain ---"
    rtk gain 2>&1 || echo "[warn] rtk gain failed"
fi
if $tokensave_enabled; then
    echo "--- tokensave gain ---"
    tokensave gain --all --range 30d 2>&1 || echo "[warn] tokensave gain failed"
fi
echo "===== end claude tools report ====="
