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

for u in root nginx www-data icecast2; do
  if id "${u}" >/dev/null 2>&1; then
    usermod -aG audio "${u}" 2>/dev/null || true
  fi
done

# Create /run/pulse/native symlink if the PulseAudio socket is elsewhere
# (e.g. HAOS provides it at /run/audio/pulse.sock)
PULSE_SOCK="${PULSE_SERVER:-}"
PULSE_SOCK="${PULSE_SOCK#unix:}"
if [ -n "${PULSE_SOCK}" ] && [ -S "${PULSE_SOCK}" ] && [ ! -S /run/pulse/native ]; then
  mkdir -p /run/pulse
  ln -sf "${PULSE_SOCK}" /run/pulse/native
fi

# Copy PulseAudio cookie for the icecast2 user so it can authenticate
if id icecast2 >/dev/null 2>&1; then
  ICECAST_HOME="$(getent passwd icecast2 | cut -d: -f6)"
  if [ -n "${ICECAST_HOME}" ]; then
    for cookie in /config/.config/pulse/cookie /root/.config/pulse/cookie; do
      if [ -f "${cookie}" ]; then
        mkdir -p "${ICECAST_HOME}/.config/pulse"
        cp "${cookie}" "${ICECAST_HOME}/.config/pulse/cookie"
        chown icecast2 "${ICECAST_HOME}/.config/pulse" "${ICECAST_HOME}/.config/pulse/cookie"
        break
      fi
    done
  fi
fi
