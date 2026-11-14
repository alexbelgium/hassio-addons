#!/usr/bin/env bash
# shellcheck shell=bash
#
# Run by the image build: fail it when the PostgreSQL or VectorChord version of this image is
# outside what the Immich shipped by this repository declares it supports. Immich refuses to
# start against a version outside its range, so such an image must not reach anyone.
#
# Only a version that is read and found outside the range fails the build. When Immich's
# declaration cannot be fetched or is written in a form not understood here, the check is
# skipped with a warning: a network error is no reason to hold back a PostgreSQL update.
set -uo pipefail

REPO="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master"

# in_range <version> <range>, the range being ">=A <B", ">=A" or "<B" as Immich writes them:
# 0 inside, 1 outside, 2 not understood
in_range() {
    local version="$1" bound
    for bound in $2; do
        case "$bound" in
            ">="*) [ "$(printf '%s\n' "${bound#>=}" "$version" | sort -V | head -n 1)" = "${bound#>=}" ] || return 1 ;;
            "<"[0-9]*) [ "$(printf '%s\n' "${bound#<}" "$version" | sort -V | head -n 1)" != "${bound#<}" ] || return 1 ;;
            *) return 2 ;;
        esac
    done
}

immich="$(curl -fsSL --retry 3 "$REPO/immich/updater.json" | sed -n 's/.*"upstream_version": *"\([^"]*\)".*/\1/p')"
constants="$(curl -fsSL --retry 3 "https://raw.githubusercontent.com/immich-app/immich/v${immich#v}/server/src/constants.ts")"
if [ -z "$immich" ] || [ -z "$constants" ]; then
    echo "WARNING: what Immich supports could not be read, compatibility is NOT checked"
    exit 0
fi

status=0
while read -r name constant version; do
    range="$(sed -n "s/.*$constant = '\(.*\)'.*/\1/p" <<< "$constants")"
    rc=0
    in_range "$version" "$range" || rc=$?
    case "$rc" in
        0) echo "$name $version is supported by Immich $immich ($range)" ;;
        1)
            echo "ERROR: $name $version is NOT supported by Immich $immich, which accepts: $range"
            status=1
            ;;
        *) echo "WARNING: range '$range' of Immich $immich for $name is not understood, NOT checked" ;;
    esac
done << EOF
PostgreSQL POSTGRES_VERSION_RANGE $PG_MAJOR.0.0
VectorChord VECTORCHORD_VERSION_RANGE $(sed -n "s/^default_version = '\(.*\)'/\1/p" "/usr/share/postgresql/$PG_MAJOR/extension/vchord.control")
EOF
exit "$status"
