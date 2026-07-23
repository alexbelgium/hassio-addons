#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Grant the shared desktop user (abc) access to the exposed GPU render nodes *before* the
# graphical services start.
#
# The LinuxServer base image already sets up /dev/dri group access, but it does so in its
# init-video s6 oneshot, which is NOT a dependency of svc-xorg/svc-selkies/svc-de. On Home
# Assistant those long-running services routinely start (as abc, via s6-setuidgid) before
# init-video has added abc to the render group, so Xorg/Selkies/pixelflux open the render
# device with the wrong credentials and fail:
#
#   libEGL warning: failed to open /dev/dri/card0: Permission denied
#
# With no usable render node the video pipeline never produces frames, so the Selkies web
# client stays on "waiting for stream" indefinitely and Claude Desktop never appears.
#
# cont-init.d runs to completion before any s6-rc service is started, so preparing the DRI
# nodes here wins that race. Everything is best-effort: a host that exposes no GPU simply has
# no nodes to touch and this is a no-op.

shopt -s nullglob
dri_nodes=(/dev/dri/card* /dev/dri/render*)
if [ "${#dri_nodes[@]}" -eq 0 ]; then
    bashio::log.info "No /dev/dri render nodes exposed; skipping GPU permission setup"
    exit 0
fi

for node in "${dri_nodes[@]}"; do
    [ -e "$node" ] || continue

    # Mirror the base image's init-video logic (add abc to the node's owning group, creating
    # the group when the GID is unnamed) but early enough that the s6-setuidgid at service
    # start picks the membership up.
    gid="$(stat -c '%g' "$node")"
    # getent exits 2 when the gid has no named group, which is the common case here: this
    # script deliberately runs before the base image's init-video/init-adduser have named the
    # passed-through /dev/dri gids. Under bashio's `set -o pipefail` + this script's `set -e`,
    # an unguarded pipeline would abort right here on that exit 2 — before the `-z "$gname"`
    # fallback below (which exists precisely to handle an unnamed gid) ever runs. Confirmed by
    # bashio manually re-running this script post-boot always "worked": by then the base
    # image's own init-video oneshot had already named the group, so getent no longer hit its
    # exit-2 path.
    if gname="$(getent group "$gid" | awk -F: '{print $1}')"; then
        rc=0
    else
        rc=$?
        if [ "$rc" -ne 2 ]; then
            bashio::log.warning "getent group ${gid} failed unexpectedly (exit ${rc}); falling back to a synthetic group"
        fi
    fi
    if [ -z "$gname" ]; then
        gname="dri${gid}"
        groupadd -o -g "$gid" "$gname" 2> /dev/null || true
    fi
    if ! id -G abc 2> /dev/null | tr ' ' '\n' | grep -qx "$gid"; then
        usermod -a -G "$gname" abc 2> /dev/null || true
    fi

    # Guarantee access even where group propagation is unreliable inside the add-on sandbox:
    # this is a single-user desktop container, so world read/write on the local render node
    # is acceptable and removes any dependency on group-membership timing.
    chmod o+rw "$node" 2> /dev/null || true

    bashio::log.info "GPU: prepared ${node} (group ${gname}:${gid}) for the desktop user"
done
