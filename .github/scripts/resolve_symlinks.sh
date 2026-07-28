#!/usr/bin/env bash
# Replace every symlink in the checked-out repository with a real copy of its target.
#
# Add-ons share files by symlinking across add-on directories (e.g. webtop/rootfs ->
# ../webtop_kde/rootfs, and files inside it -> ../../../../claude_desktop/rootfs/...). A
# Docker build context is a single add-on directory, so any symlink that escapes it has to be
# materialised before the build.
#
# The loop repeats because resolving one symlink can create others: copying a directory
# symlink with `cp -a` preserves the symlinks *inside* it, and those copies are not part of
# the file list the current pass is iterating over. Repeating until a pass finds nothing makes
# the result independent of the order `find` happens to return.
set -euo pipefail

for _ in 1 2 3 4 5; do
    mapfile -t links < <(find . -type l)
    if [ "${#links[@]}" -eq 0 ]; then
        exit 0
    fi

    for link in "${links[@]}"; do
        target=$(readlink -f "$link" || true)
        if [ -z "$target" ] || [ ! -e "$target" ]; then
            echo "Removing broken symlink: $link -> $(readlink "$link")"
            rm -f "$link"
            continue
        fi

        rm "$link"
        if [ -d "$target" ]; then
            mkdir -p "$link"
            cp -a "$target/." "$link/"
        else
            cp "$target" "$link"
        fi
    done
done

if [ -n "$(find . -type l)" ]; then
    echo "::error::Symlinks still present after 5 resolution passes; possible symlink cycle"
    find . -type l
    exit 1
fi
