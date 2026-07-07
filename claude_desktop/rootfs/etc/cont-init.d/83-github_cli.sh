#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

if ! bashio::config.true 'install_github_cli'; then
    bashio::log.info "GitHub CLI setup disabled"
    exit 0
fi

if ! command -v git > /dev/null 2>&1; then
    bashio::log.warning "git is not available"
fi

if ! command -v gh > /dev/null 2>&1; then
    bashio::log.warning "gh is not available"
    exit 0
fi

if bashio::config.has_value 'github_username'; then
    git config --global user.name "$(bashio::config 'github_username')"
fi

if bashio::config.has_value 'github_email'; then
    git config --global user.email "$(bashio::config 'github_email')"
fi

if bashio::config.has_value 'github_token'; then
    token="$(bashio::config 'github_token')"
    mkdir -p "$HOME/.config/gh"
    chmod 700 "$HOME/.config/gh"
    export GH_TOKEN="$token"
    export GITHUB_TOKEN="$token"
    if gh auth status --hostname github.com > /dev/null 2>&1; then
        bashio::log.info "GitHub CLI already authenticated for github.com"
    else
        bashio::log.info "Configuring GitHub CLI authentication for github.com"
        printf '%s\n' "$token" | gh auth login --hostname github.com --with-token || bashio::log.warning "GitHub CLI authentication failed"
    fi
    gh auth setup-git --hostname github.com || bashio::log.warning "GitHub CLI git credential setup failed"
else
    bashio::log.info "GitHub CLI available. Set github_token to authenticate gh and git operations."
fi
