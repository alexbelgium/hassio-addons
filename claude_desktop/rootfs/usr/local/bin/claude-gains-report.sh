#!/usr/bin/with-contenv bashio
# Hourly rtk + headroom token-savings snapshot for the add-on log.
# Invoked by cron (see /defaults/crontabs/root); its stdout is redirected to /proc/1/fd/1,
# so the report appears in the add-on log. Doubles as a heartbeat: if the numbers stop
# growing, the corresponding tool has stopped working.
# with-contenv supplies HOME from the s6 envdir, so this honors a custom `data_location`
# (see 20-folders.sh) instead of hardcoding /data/data; it also makes bashio::config
# available for the install_headroom gate below.
export NO_COLOR=1                                   # keep the add-on log free of ANSI color codes
export PATH="/lsiopy/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

have_rtk=false;      command -v rtk >/dev/null 2>&1      && have_rtk=true
have_headroom=false; command -v headroom >/dev/null 2>&1 && have_headroom=true

# headroom is pip-installed unconditionally at build time, so its binary is on PATH even
# when install_headroom is off — gate on the same config svc-headroom checks, and only
# fall back to have_headroom as a secondary availability guard.
headroom_enabled=false
if bashio::config.true 'install_headroom' && $have_headroom; then
    headroom_enabled=true
fi

# Nothing to report if neither tool is active — stay quiet.
if ! $have_rtk && ! $headroom_enabled; then exit 0; fi

echo "===== claude gains report $(date '+%Y-%m-%d %H:%M:%S') ====="
if $have_rtk; then
    echo "--- rtk gain ---"
    rtk gain 2>&1 || echo "[warn] rtk gain failed"
fi
if $headroom_enabled; then
    echo "--- headroom savings ---"
    headroom savings 2>&1 || echo "[warn] headroom savings failed"
fi
echo "===== end gains report ====="
