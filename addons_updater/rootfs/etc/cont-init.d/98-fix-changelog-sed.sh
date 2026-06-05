#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

UPDATER_SCRIPT="/etc/cont-init.d/99-run.sh"

if [ ! -f "$UPDATER_SCRIPT" ]; then
    exit 0
fi

python3 - "$UPDATER_SCRIPT" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = '            sed -i "1i " "/data/${BASENAME}/${SLUG}/CHANGELOG.md"'
new = '''            {
                tmp_changelog=$(mktemp)
                printf '\\n' > "$tmp_changelog"
                cat "/data/${BASENAME}/${SLUG}/CHANGELOG.md" >> "$tmp_changelog"
                mv "$tmp_changelog" "/data/${BASENAME}/${SLUG}/CHANGELOG.md"
            }'''

if old in text and new not in text:
    path.write_text(text.replace(old, new, 1))
PY
