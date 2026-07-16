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

# Everything below writes into the abc runtime user's HOME, so it must run AS abc. cont-init
# runs as root with HOME already pointing at the persistent data location, so plain
# `git config --global` recreated ~/.gitconfig owned by root:root on every start — and because
# that file is rewritten each boot, 20-folders.sh's earlier recursive chown never stuck to it.
# The user who actually runs git, gh and Claude was then unable to read its own committer
# identity or the gh credential helper, so every commit failed with "Author identity unknown"
# and authenticated pushes fell back to prompting. 20-folders.sh already remapped abc to the
# effective runtime identity (never root in bypass mode), so follow abc rather than re-reading
# the raw PUID/PGID options here.
RUNTIME_UID="$(id -u abc)"
RUNTIME_GID="$(id -g abc)"

run_as_runtime_user() {
    s6-setuidgid abc env HOME="$HOME" "$@"
}

# Reclaim any root-owned copies left by an earlier add-on version before writing as abc:
# these paths are not covered by 82-claude_tools.sh's ownership pass, and a root-owned
# ~/.gitconfig would make the first `git config` below fail outright under `set -e`.
for managed_path in "$HOME/.gitconfig" "$HOME/.config/gh"; do
    if [ -e "$managed_path" ]; then
        chown -R -- "${RUNTIME_UID}:${RUNTIME_GID}" "$managed_path" || bashio::log.warning "Unable to set ownership on $managed_path"
    fi
done

if bashio::config.has_value 'github_username'; then
    run_as_runtime_user git config --global user.name "$(bashio::config 'github_username')"
fi

if bashio::config.has_value 'github_email'; then
    run_as_runtime_user git config --global user.email "$(bashio::config 'github_email')"
fi

if bashio::config.has_value 'github_token'; then
    token="$(bashio::config 'github_token')"
    run_as_runtime_user mkdir -p "$HOME/.config/gh"
    run_as_runtime_user chmod 700 "$HOME/.config/gh"
    if run_as_runtime_user env -u GH_TOKEN -u GITHUB_TOKEN gh auth status --hostname github.com > /dev/null 2>&1; then
        bashio::log.info "GitHub CLI already authenticated for github.com"
    else
        bashio::log.info "Configuring GitHub CLI authentication for github.com"
        printf '%s\n' "$token" | run_as_runtime_user env -u GH_TOKEN -u GITHUB_TOKEN gh auth login --hostname github.com --with-token || bashio::log.warning "GitHub CLI authentication failed"
    fi
    run_as_runtime_user env -u GH_TOKEN -u GITHUB_TOKEN gh auth setup-git --hostname github.com || bashio::log.warning "GitHub CLI git credential setup failed"
else
    bashio::log.info "GitHub CLI available. Set github_token to authenticate gh and git operations."
fi
