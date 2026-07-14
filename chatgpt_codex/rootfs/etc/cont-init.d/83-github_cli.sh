#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

if bashio::config.has_value 'github_username'; then
    s6-setuidgid abc git config --global user.name "$(bashio::config 'github_username')"
fi

if bashio::config.has_value 'github_email'; then
    s6-setuidgid abc git config --global user.email "$(bashio::config 'github_email')"
fi

if bashio::config.has_value 'github_token'; then
    token="$(bashio::config 'github_token')"
    if s6-setuidgid abc env -u GH_TOKEN -u GITHUB_TOKEN gh auth status --hostname github.com > /dev/null 2>&1; then
        bashio::log.info "GitHub CLI is already authenticated"
    else
        bashio::log.info "Authenticating GitHub CLI"
        printf '%s\n' "$token" | s6-setuidgid abc env -u GH_TOKEN -u GITHUB_TOKEN \
            gh auth login --hostname github.com --with-token || \
            bashio::log.warning "GitHub CLI authentication failed"
    fi
    s6-setuidgid abc env -u GH_TOKEN -u GITHUB_TOKEN \
        gh auth setup-git --hostname github.com || \
        bashio::log.warning "GitHub CLI git credential setup failed"
else
    bashio::log.info "Set github_token to authenticate gh and Git operations"
fi
