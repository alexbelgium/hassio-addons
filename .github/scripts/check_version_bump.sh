#!/usr/bin/env bash
# Destination: .github/scripts/check_version_bump.sh
#
# Fails a pull request that changes what an add-on ships without bumping that
# add-on's `version`. Supervisor only offers a rebuild when `version` changes,
# so a fix merged without one leaves every user on the old image: merged, inert,
# and the issue looks closed. Nothing else in CI checks this.
#
# It deliberately does NOT reuse check-addon-changes' `changedAddons`. That
# output is built from `^<addon>/config\.(json|ya?ml)$` alone, so it is empty
# for exactly the pull requests this check exists to catch — an add-on whose
# scripts changed while config.yaml did not. Reusing it would make this a no-op.
# This scan is local to this check and does not affect which add-ons get linted
# or built.
#
# Env:
#   BASE_SHA (required) — commit this PR is diffed against
#   HEAD_SHA (required) — the PR's merge commit
#
# Exit 0 = every add-on that needs a bump got one (or nothing relevant changed).

set -euo pipefail

: "${BASE_SHA:?BASE_SHA must be set}"
: "${HEAD_SHA:?HEAD_SHA must be set}"

# Files that ship to users only as repo metadata, or that bots rewrite on their
# own schedule. Changing one of these alone does not require anybody to receive
# a new image, so it must not demand a version bump — otherwise every changelog
# or stats-graph commit would fail CI.
#
# Everything else under an add-on directory counts: Dockerfile, rootfs/,
# build.json|yaml (base images), apparmor.txt and translations/ (Supervisor
# re-reads them on update), root-level *.sh that Dockerfiles COPY, and
# config.yaml itself — an added option or changed port needs the update offered
# just as much as a code change does. Allowlisting the ignorable and treating
# the remainder as significant fails closed: a new kind of file defaults to
# "needs a bump" rather than silently escaping the check.
is_ignorable() {
    local rel="$1"   # path relative to the add-on directory
    # addon/images/** is artwork; addon/rootfs/**/images/** is shipped content,
    # so this must be anchored at the add-on root rather than matching any
    # path that happens to contain an "images" segment.
    case "$rel" in
        images/*) return 0 ;;
    esac
    # Anything else nested ships inside the image (rootfs/, translations/, ...).
    case "$rel" in
        */*) return 1 ;;
    esac
    case "$rel" in
        CHANGELOG.md | updater.json | stats.png | icon.png | logo.png | *.md) return 0 ;;
    esac
    return 1
}

# An add-on is a top-level directory with a config file. Tested against the
# BASE tree so a directory deleted by this PR is still recognised (and then
# skipped below), and .github/, .templates/ and .claude/ are excluded for free
# by simply not having one.
addon_config_at() {
    local ref="$1" addon="$2" f
    for f in config.yaml config.yml config.json; do
        if git cat-file -e "${ref}:${addon}/${f}" 2> /dev/null; then
            printf '%s' "$f"
            return 0
        fi
    done
    return 1
}

# Reads the add-on's declared version. JSON goes through jq so a minified or
# reordered config.json is read correctly rather than silently returning empty.
# YAML is matched at column 0 on purpose: an indented `version:` belongs to a
# nested mapping (a schema entry, an option literally named version) and
# comparing it would compare the wrong value. A trailing YAML comment is
# stripped before quotes so `version: "1.2.3" # note` does not read as a bump.
version_at() {
    local ref="$1" path="$2" content
    content=$(git show "${ref}:${path}" 2> /dev/null) || return 1
    case "$path" in
        *.json)
            printf '%s' "$content" | jq -r '.version // empty' 2> /dev/null
            ;;
        *)
            printf '%s\n' "$content" |
                grep -m1 -E '^version[[:space:]]*:' |
                sed -E 's/^version[[:space:]]*:[[:space:]]*//; s/[[:space:]]+#.*$//; s/^["'\'']//; s/["'\'']$//; s/[[:space:]]*$//'
            ;;
    esac
}

mapfile -t CHANGED < <(git diff --name-only "$BASE_SHA" "$HEAD_SHA")

declare -A NEEDS_BUMP=()
for file in "${CHANGED[@]}"; do
    [ -n "$file" ] || continue
    case "$file" in */*) ;; *) continue ;; esac   # top-level files are not add-ons
    addon="${file%%/*}"
    is_ignorable "${file#*/}" && continue
    addon_config_at "$BASE_SHA" "$addon" > /dev/null 2>&1 || continue
    NEEDS_BUMP["$addon"]=1
done

if [ "${#NEEDS_BUMP[@]}" -eq 0 ]; then
    echo "No add-on changes that require a version bump."
    exit 0
fi

FAILED=0
for addon in $(printf '%s\n' "${!NEEDS_BUMP[@]}" | sort); do
    base_cfg=$(addon_config_at "$BASE_SHA" "$addon")
    # Resolved separately at HEAD: an add-on that renames its manifest between
    # supported names (config.yaml -> config.yml) while changing shipped files
    # would otherwise be read at the old path, come back empty, and slip through.
    if ! head_cfg=$(addon_config_at "$HEAD_SHA" "$addon"); then
        echo "  $addon: removed by this PR, skipping"
        continue
    fi
    old=$(version_at "$BASE_SHA" "$addon/$base_cfg" || true)
    new=$(version_at "$HEAD_SHA" "$addon/$head_cfg" || true)
    # Fail closed. An unreadable version used to warn and skip, which let the
    # job go green on exactly the add-ons whose manifest this check could not
    # understand — the opposite of what it is for.
    if [ -z "$old" ] || [ -z "$new" ]; then
        echo "::error file=$addon/$head_cfg::$addon: could not read a version from $base_cfg (base) or $head_cfg (head). Refusing to pass a check that could not be performed."
        FAILED=1
        continue
    fi
    if [ "$old" = "$new" ]; then
        echo "::error file=$addon/$head_cfg::$addon ships changed files but version is still $old. Supervisor only offers a rebuild when version changes, so this would merge without reaching anyone. Bump it following this add-on's own convention: for a local patch counter take the boundary from updater.json's upstream_version (append .1 when version equals it, otherwise increment the digits after it); date-based and LSIO-style versions have no counter and follow their own scheme."
        FAILED=1
    else
        echo "  $addon: $old -> $new"
    fi
done

if [ "$FAILED" -ne 0 ]; then
    echo "::error::One or more add-ons changed without a version bump. Add the 'skip-version-check' label and re-run this job if that is deliberate."
    exit 1
fi

echo "All changed add-ons have a version bump."
