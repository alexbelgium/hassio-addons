#!/usr/bin/env bash
# Run every linter that CI will run and that works locally. The Docker build is deliberately not
# attempted: dockerd does not start in this environment, so CI is the only gate for it — say that
# rather than implying the build was checked.
#
# --vs-master re-lints each changed file at origin/master and prints only findings your diff
# ADDED, and fails if there are any. Without it you will chase warnings that were already there.
#
# Usage: validate.sh [addon-dir] [--vs-master]
set -uo pipefail
# git diff prints repo-root-relative paths and $ADDON is a top-level directory name: neither
# resolves from a subdirectory, where the -f guard below would skip every file and report clean.
if root=$(git rev-parse --show-toplevel 2> /dev/null); then cd "$root" || exit 1; fi

ADDON="${1:-}"
[ "${ADDON:-}" = "--vs-master" ] && { ADDON=""; set -- --vs-master; }
VS_MASTER=false
for a in "$@"; do [ "$a" = "--vs-master" ] && VS_MASTER=true; done

if [ -z "$ADDON" ]; then
    mapfile -t _dirs < <(git diff --name-only origin/master...HEAD 2> /dev/null |
        cut -d/ -f1 | sort -u | grep -vE '^\.' )
    if [ "${#_dirs[@]}" -gt 1 ]; then
        echo "several changed dirs: ${_dirs[*]}"
        echo "pass one explicitly: validate.sh <addon-dir>"; exit 1
    fi
    ADDON="${_dirs[0]:-}"
fi
[ -z "$ADDON" ] && { echo "usage: validate.sh <addon-dir> [--vs-master]"; exit 1; }
git rev-parse --verify origin/master > /dev/null 2>&1 || {
    echo "origin/master missing — run: git fetch origin master"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
echo "== validating $ADDON =="

fail=0
note() { printf '  %-13s %s\n' "$1" "$2"; }
# execline `run`/`finish` files are not shell (25 of them here, across 21 add-ons). Neither
# linter below can read one, so anything either says about it is noise.
is_execline() { local l; IFS= read -r l < "$1" 2> /dev/null; [[ $l == '#!'*execlineb* ]]; }

# Shell: bash -n then shellcheck -x (follows sourced files, as CI does). One list for both.
files=()
while IFS= read -r f; do is_execline "$f" || files+=("$f"); done \
    < <(find "$ADDON" -type f \( -name '*.sh' -o -name 'run' -o -name 'finish' -o -name 'autostart' \) 2> /dev/null)
for f in "${files[@]}"; do
    if ! out=$(bash -n "$f" 2>&1); then note "bash -n" "FAIL $f"; echo "$out" | sed 's/^/      /'; fail=1; fi
done
[ "$fail" -eq 0 ] && note "bash -n" "${#files[@]} file(s) checked"

if [ "${#files[@]}" -gt 0 ] && command -v shellcheck > /dev/null 2>&1; then
    sc=$(shellcheck -x -f gcc "${files[@]}" 2>&1)
    if [ -n "$sc" ]; then
        note "shellcheck" "$(printf '%s\n' "$sc" | grep -c .) finding(s)"
        printf '%s\n' "$sc" | sed 's/^/      /' | head -20
    else note "shellcheck" "clean"; fi
fi

command -v hadolint > /dev/null 2>&1 && [ -f "$ADDON/Dockerfile" ] && {
    hl=$(hadolint "$ADDON/Dockerfile" 2>&1)
    if [ -n "$hl" ]; then
        note "hadolint" "$(printf '%s\n' "$hl" | grep -c .) finding(s)"
        printf '%s\n' "$hl" | sed 's/^/      /' | head -10
    else note "hadolint" "clean"; fi
}

if [ -f "$ADDON/config.yaml" ]; then
    # path passed as argv, never interpolated into Python source
    python3 - "$ADDON/config.yaml" <<'PY' || { note "config.yaml" "FAIL parse"; fail=1; }
import yaml,sys
d=yaml.safe_load(open(sys.argv[1]))
print('  %-13s ok (version=%s, %d options)' % ('config.yaml', d.get('version'), len(d.get('options') or {})))
missing=[k for k in (d.get('options') or {}) if k not in (d.get('schema') or {})]
if missing: print('  %-13s options with no schema entry: %s' % ('WARN', missing)); sys.exit(0)
PY
    command -v yamllint > /dev/null 2>&1 && {
        yl=$(yamllint -f parsable "$ADDON/config.yaml" 2>&1 | grep -c .)
        note "yamllint" "$yl finding(s) (compare with --vs-master)"
    }
fi

while IFS= read -r f; do
    python3 -m py_compile "$f" 2> /dev/null || { note "py_compile" "FAIL $f"; fail=1; }
done < <(find "$ADDON" -type f -name '*.py' 2> /dev/null)

$VS_MASTER && command -v npx > /dev/null 2>&1 && [ -f "$ADDON/CHANGELOG.md" ] && {
    md=$(npx --yes markdownlint-cli2 "$ADDON/CHANGELOG.md" 2>&1 | grep -cE "CHANGELOG.md:[0-9]+")
    note "markdownlint" "$md finding(s) in CHANGELOG (mostly pre-existing; lint is continue-on-error in CI)"
}

echo
echo "== CI requirements =="
# -Fxq, not -q: unanchored, seerr's is matched by zzz_archived_overseerr's, and . is a wildcard.
# Stricter than the gate itself, whose quoted =~ accepts that same collision
# (onpr_check-pr.yaml:75), so this can fail where CI passes — the wrong add-on's is still wrong.
if git diff --name-only origin/master...HEAD 2> /dev/null | grep -Fxq "$ADDON/CHANGELOG.md"; then
    note "CHANGELOG" "updated"
else
    # This one IS gated: onpr_check-pr.yaml exits 1 without it.
    note "CHANGELOG" "NOT UPDATED for $ADDON — CI hard-gates this"; fail=1
fi
if git diff origin/master...HEAD -- "$ADDON/config.yaml" 2> /dev/null | grep -q '^+version:'; then
    note "version" "bumped"
else
    # Repo convention and required for the rebuild to be offered — but no workflow gates it,
    # so this is a warning, not a failure.
    note "version" "NOT bumped (convention; no rebuild will be offered) — not a CI gate"
fi
note "docker build" "NOT tested locally (dockerd unavailable) — CI is the only gate"

if $VS_MASTER; then
    echo
    echo "== findings ADDED by this diff (pre-existing ones filtered out) =="
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    added=0
    # Fed by process substitution, not a pipe: a pipeline runs this in a subshell, where the
    # findings below could never reach $fail and the verdict would contradict the list.
    while IFS= read -r f; do
        # Deleted: linting the path that is gone invents a finding. Added: no base, and an
        # empty one says the right thing — every finding in it is one this diff added.
        [ -f "$f" ] || continue
        is_execline "$f" && continue
        git show "origin/master:$f" > "$tmp/base" 2> /dev/null || : > "$tmp/base"
        # A missing linter must be a visible skip, not a silent "no new findings":
        # its "command not found" error is identical for base and head, so comm would
        # cancel it out and report a false clean.
        case "$f" in
            *.sh | *autostart | */run | */finish)
                command -v shellcheck > /dev/null 2>&1 || { echo "  $f: SKIPPED (shellcheck not installed)"; continue; }
                cmd() { shellcheck -x -f gcc "$1" 2>&1 | sed 's/^[^:]*:[0-9]*:[0-9]*://'; } ;;
            *.yaml | *.yml)
                command -v yamllint > /dev/null 2>&1 || { echo "  $f: SKIPPED (yamllint not installed)"; continue; }
                cmd() { yamllint -f parsable "$1" 2>&1 | sed 's/^[^:]*//; s/^:[0-9]*:[0-9]*//'; } ;;
            *Dockerfile)
                command -v hadolint > /dev/null 2>&1 || { echo "  $f: SKIPPED (hadolint not installed)"; continue; }
                cmd() { hadolint "$1" 2>&1 | sed 's/^[^:]*//; s/^:[0-9]*//'; } ;;
            *) continue ;;
        esac
        b=$(cmd "$tmp/base" | sort)
        a=$(cmd "$f" | sort)
        new=$(comm -13 <(printf '%s\n' "$b") <(printf '%s\n' "$a"))
        [ -n "$new" ] && {
            echo "  $f: $(printf '%s\n' "$new" | grep -c .) NEW finding(s)"
            printf '%s\n' "$new" | sed 's/^/      /' | head -5
            added=1; fail=1
        }
    done < <(git diff --name-only origin/master...HEAD -- "$ADDON" 2> /dev/null)
    [ "$added" -eq 0 ] && echo "  (none — this diff introduced no new lint findings)"
fi

echo
[ "$fail" -eq 0 ] && echo "== local validation passed ==" || echo "== local validation FAILED =="
exit "$fail"
