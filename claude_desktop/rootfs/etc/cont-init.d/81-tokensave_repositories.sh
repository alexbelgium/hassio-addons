#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
set -o pipefail

if ! bashio::config.true 'install_tokensave' || ! command -v git > /dev/null 2>&1; then
    exit 0
fi

declare -A REPOS_SEEN=()
# bashio::config prints its result without a trailing newline, so the last record arrives
# with read returning non-zero; the extra test keeps that final path in the loop.
while IFS= read -r configured_path || [ -n "$configured_path" ]; do
    configured_path="${configured_path#"${configured_path%%[![:space:]]*}"}"
    configured_path="${configured_path%"${configured_path##*[![:space:]]}"}"
    if [ -z "$configured_path" ] || [ "$configured_path" = "null" ]; then
        continue
    fi

    case "$configured_path" in
        /*) ;;
        *) continue ;;
    esac
    [ -d "$configured_path" ] || continue

    # The one-shot safe.directory override is used only to discover the repository root.
    # Persist the resolved root in the shared runtime user's Git config before 82-claude_tools.sh
    # performs normal repository detection, avoiding Git's dubious-ownership rejection.
    repo_root="$(s6-setuidgid abc env HOME="$HOME" \
        git -c safe.directory='*' -C "$configured_path" rev-parse --show-toplevel 2> /dev/null || true)"
    [ -n "$repo_root" ] && [ "$repo_root" != "/" ] || continue
    [[ -z "${REPOS_SEEN[$repo_root]:-}" ]] || continue
    REPOS_SEEN[$repo_root]=1

    if ! s6-setuidgid abc env HOME="$HOME" git config --global --get-all safe.directory \
        | grep -Fxq -- "$repo_root"; then
        s6-setuidgid abc env HOME="$HOME" git config --global --add safe.directory "$repo_root"
        bashio::log.info "Marked TokenSave repository as safe for Git: ${repo_root}"
    fi
# bashio::config prints list options one entry per line ("null" when the key is absent);
# bashio::config.array only exists in the repo's standalone bashio, not in the real bashio here.
done < <(bashio::config 'tokensave_project_paths')
