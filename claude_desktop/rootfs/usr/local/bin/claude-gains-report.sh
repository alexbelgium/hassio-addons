#!/usr/bin/env bash
# Hourly rtk + headroom token-savings snapshot for the add-on log.
# Invoked by cron (see /defaults/crontabs/root); its stdout is redirected to /proc/1/fd/1,
# so the report appears in the add-on log. Doubles as a heartbeat: if the numbers stop
# growing, the corresponding tool has stopped working.
export HOME=/data/data
export NO_COLOR=1                                   # keep the add-on log free of ANSI color codes
export PATH="/lsiopy/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

have_rtk=false;      command -v rtk >/dev/null 2>&1      && have_rtk=true
have_headroom=false; command -v headroom >/dev/null 2>&1 && have_headroom=true

# Nothing to report if neither tool is installed — stay quiet.
if ! $have_rtk && ! $have_headroom; then exit 0; fi

echo "===== claude gains report $(date '+%Y-%m-%d %H:%M:%S') ====="
if $have_rtk; then
    echo "--- rtk gain ---"
    rtk gain 2>&1 || echo "[warn] rtk gain failed"
fi
if $have_headroom; then
    echo "--- headroom savings ---"
    headroom savings 2>&1 || echo "[warn] headroom savings failed"
fi
echo "===== end gains report ====="
