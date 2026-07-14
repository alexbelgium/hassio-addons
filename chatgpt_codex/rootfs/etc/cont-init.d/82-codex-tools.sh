#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

PUID="$(bashio::config 'PUID')"
PGID="$(bashio::config 'PGID')"

if ! command -v codex > /dev/null 2>&1; then
    bashio::log.fatal "Codex CLI is not available"
    exit 1
fi
if ! command -v headroom > /dev/null 2>&1; then
    bashio::log.fatal "Headroom is not available"
    exit 1
fi
if ! command -v rtk > /dev/null 2>&1; then
    bashio::log.fatal "RTK is not available"
    exit 1
fi

bashio::log.info "Codex: $(codex --version 2>&1 | head -n 1)"
bashio::log.info "Headroom: $(headroom --version 2>&1 | head -n 1)"
bashio::log.info "RTK: $(rtk --version 2>&1 | head -n 1)"

# Configure RTK's native Codex integration ahead of the first wrapped session.
if ! s6-setuidgid abc env \
    HOME="$HOME" \
    CODEX_HOME="${CODEX_HOME:-$HOME/.codex}" \
    PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" \
    RTK_NONINTERACTIVE=1 \
    rtk init -g --codex; then
    bashio::log.warning "RTK Codex initialization failed; Headroom will retry when wrapping Codex"
fi

for key in CODEX_AUTO_START CODEX_USE_HEADROOM HEADROOM_OUTPUT_SHAPER HEADROOM_CODE_AWARE_ENABLED; do
    case "$key" in
        CODEX_AUTO_START)
            bashio::config.true 'auto_start_codex' && value="1" || value="0"
            ;;
        CODEX_USE_HEADROOM)
            bashio::config.true 'use_headroom' && value="1" || value="0"
            ;;
        HEADROOM_OUTPUT_SHAPER)
            bashio::config.true 'headroom_output_shaper' && value="1" || value="0"
            ;;
        HEADROOM_CODE_AWARE_ENABLED)
            bashio::config.true 'headroom_code_aware' && value="1" || value="0"
            ;;
    esac
    printf '%s' "$value" > "/run/s6/container_environment/$key"
done
printf '%s' 'rtk' > /run/s6/container_environment/HEADROOM_CONTEXT_TOOL

chown -R "$PUID:$PGID" "$HOME/.codex" "$HOME/.headroom"
