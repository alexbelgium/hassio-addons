#!/usr/bin/env bash
# RAM/CPU snapshot of the running add-on, built to avoid the two mistakes that make such
# snapshots wrong:
#
#   1. Summed RSS double-counts shared pages. Removing a duplicate process frees its *private*
#      memory, not its RSS. So PSS and private are reported alongside, and private is the number
#      to quote when arguing "removing this saves N MB".
#   2. A big mapping is not necessarily resident. Large SysV/tmpfs segments are lazily populated,
#      so reserved size is reported separately from resident.
#
# Note /proc/meminfo and free show HOST figures (no memory cgroup namespace) — never attribute
# those to the add-on.
#
# Usage: measure.sh [cpu-sample-seconds]   (default 20)
set -uo pipefail
SAMPLE="${1:-20}"
if [ "$SAMPLE" -lt 20 ]; then
    echo "WARNING: a ${SAMPLE}s sample understates CPU badly (a 3s sample measured 2.3% where" >&2
    echo "         20s measured 21.6% for the same process). Use >=20s for anything you report." >&2
fi
OUT="${SCRATCH:-${TMPDIR:-/tmp}}/addon-measure.$$"
mkdir -p "$OUT"

# rtk filters some output; redirect to a file to get the complete list.
ps -eo pid,ppid,user,rss,pcpu,etimes,args --sort=-rss > "$OUT/ps.txt" 2>&1

echo "== totals =="
awk 'NR>1{s+=$4; n++} END{printf "  processes=%d  summed RSS=%.0f MB (overstates: shared pages counted per-process)\n", n, s/1024}' "$OUT/ps.txt"
awk '{t+=$2} END{printf "  threads=%d\n", t}' <(ps -eo pid,nlwp --no-headers 2> /dev/null)

echo
echo "== per-process memory (top 20 by PSS) =="
printf '  %-28s %8s %8s %8s\n' COMMAND RSS PSS PRIVATE
python3 - "$OUT" <<'PY'
import os, sys
rows = []
for pid in filter(str.isdigit, os.listdir('/proc')):
    try:
        cmd = open(f'/proc/{pid}/cmdline', 'rb').read().replace(b'\x00', b' ').decode(errors='replace').strip()
        if not cmd:
            continue
        rss = pss = priv = 0
        for line in open(f'/proc/{pid}/smaps_rollup'):
            k, _, v = line.partition(':')
            v = v.split()[0] if v.split() else '0'
            if k == 'Rss': rss = int(v)
            elif k == 'Pss': pss = int(v)
            elif k in ('Private_Dirty', 'Private_Clean'): priv += int(v)
    except Exception:
        continue
    rows.append((pss, rss, priv, pid, cmd))
rows.sort(reverse=True)
tr = tp = tv = 0
for pss, rss, priv, pid, cmd in rows:
    tr += rss; tp += pss; tv += priv
for pss, rss, priv, pid, cmd in rows[:20]:
    name = (cmd[:26] + '..') if len(cmd) > 28 else cmd
    print(f"  {name:<28} {rss/1024:7.0f}M {pss/1024:7.0f}M {priv/1024:7.0f}M")
print(f"\n  {'TOTAL':<28} {tr/1024:7.0f}M {tp/1024:7.0f}M {tv/1024:7.0f}M")
print("  ^ quote PRIVATE when claiming what removing a process would free.")
PY

echo
echo "== reserved-but-not-resident (lazy allocations, NOT leaks) =="
ipcs -m 2>/dev/null | awk 'NR>3 && $5 ~ /^[0-9]+$/ && $5 > 50000000 {printf "  SysV shm %.0f MB (owner %s) — check Rss in /proc/<pid>/smaps before calling it used\n", $5/1048576, $3}'

echo
echo "== CPU over ${SAMPLE}s (idle unless you are driving the UI) =="
# utime+stime. Parsed after the LAST ')' because field 2 is (comm) and may contain spaces —
# a plain $14+$15 is wrong for anything like 'npm exec @foo' and silently reports a fabricated
# number rather than failing.
jiffies() { awk -F') ' '{n=split($NF,a," "); print a[12]+a[13]}' "/proc/$1/stat" 2>/dev/null; }

# jiffies are USER_HZ units — almost always 100, but read it rather than assume it
HZ=$(getconf CLK_TCK 2>/dev/null) && [ "$HZ" -gt 0 ] 2>/dev/null || HZ=100

# Sample EVERY readable process, not the top-N of ps.txt: that list is sorted by RSS,
# and the busiest process is not necessarily a big one.
declare -A t0
for d in /proc/[0-9]*; do
    pid=${d#/proc/}
    [ -r "$d/stat" ] && t0[$pid]=$(jiffies "$pid")
done
sleep "$SAMPLE"
for pid in "${!t0[@]}"; do
    [ -r "/proc/$pid/stat" ] || continue
    t1=$(jiffies "$pid") || continue
    [ -n "$t1" ] && [ -n "${t0[$pid]}" ] || continue
    delta=$(( t1 - ${t0[$pid]} ))
    [ "$delta" -gt 0 ] || continue
    pct=$(awk -v d="$delta" -v s="$SAMPLE" -v hz="$HZ" 'BEGIN{printf "%.2f", d*100/(hz*s)}')
    comm=$(tr -d '\0' < "/proc/$pid/comm" 2>/dev/null)
    echo "$pct $pid $comm"
done | sort -rn | head -12 | awk '{printf "  %6s%%  %-8s %s\n", $1, $2, $3}'

echo
echo "  established conns on :8082/:3000/:3001 = $(ss -tn 2>/dev/null | grep -cE 'ESTAB.*:(8082|3000|3001)')"
echo "  (those are claude_desktop/webtop viewer ports; 0 here means CPU above is idle burn)"
echo "  raw ps: $OUT/ps.txt"
