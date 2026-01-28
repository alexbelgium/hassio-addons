#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

SND_GID=""
if [ -e /dev/snd ] && command -v stat >/dev/null 2>&1; then
  SND_GID="$(stat -c '%g' /dev/snd 2>/dev/null || true)"
fi

if [ -n "${SND_GID}" ] && getent group audio >/dev/null 2>&1; then
  current_gid="$(getent group audio | cut -d: -f3 || true)"
  if [ -n "${current_gid}" ] && [ "${current_gid}" != "${SND_GID}" ]; then
    groupmod -g "${SND_GID}" audio 2>/dev/null || true
  fi
fi

for u in root nginx www-data; do
  if id "${u}" >/dev/null 2>&1; then
    usermod -aG audio "${u}" 2>/dev/null || true
  fi
done
