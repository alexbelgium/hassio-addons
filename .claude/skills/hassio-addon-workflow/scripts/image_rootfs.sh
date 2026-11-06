#!/usr/bin/env bash
# Unpack a container image's filesystem without dockerd, so the real artifact can be run.
#
# There is no dockerd on this host, so "CI is the only gate" used to mean a bug in an add-on that
# is not installed here got diagnosed by reading upstream source — which guessed wrong on #3204.
# Pulling the layers straight from the registry and running the app with the image's own runtime
# found the cause in minutes (PR #3205). This does the pull; references/evidence.md says how to
# run what it unpacks.
#
# Usage: image_rootfs.sh <image[:tag]> <dest-dir> [arch]   # arch defaults to this host's (amd64/arm64)
#   image_rootfs.sh docker.io/diegosouzapw/omniroute:3.8.52 /data/claude/.work/repro-3204/root
# Prints the image config (Env, Entrypoint, Cmd, WorkingDir) last. Dest must be under /data:
# /tmp is noexec. Device nodes and ownership are skipped (no root), which is fine for app code.
set -euo pipefail

ref="${1:?image[:tag]}"; dest="${2:?dest dir}"
arch="${3:-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')}"
case "$ref" in */*.*/*|*.*/*) ;; */*) ref="docker.io/$ref" ;; *) ref="docker.io/library/$ref" ;; esac
reg="${ref%%/*}"; repo="${ref#*/}"; tag="${repo##*:}"; [ "$tag" = "$repo" ] && tag=latest; repo="${repo%:*}"
api="https://$reg"; [ "$reg" = docker.io ] && api="https://registry-1.docker.io"

# Anonymous pull token from whatever realm the registry advertises (Docker Hub, ghcr, quay, ...).
chal="$(curl -sI "$api/v2/$repo/manifests/$tag" | tr -d '\r' | grep -i '^www-authenticate:' || true)"
auth=()
if [ -n "$chal" ]; then
  realm="$(sed -E 's/.*realm="([^"]+)".*/\1/' <<<"$chal")"
  service="$(sed -nE 's/.*service="([^"]+)".*/\1/p' <<<"$chal")"
  tok="$(curl -sf "$realm?service=$service&scope=repository:$repo:pull" | python3 -Ic 'import sys,json;d=json.load(sys.stdin);print(d.get("token") or d["access_token"])')"
  auth=(-H "Authorization: Bearer $tok")
fi
get() { curl -sfL "${auth[@]}" "$@"; }
accept="application/vnd.oci.image.index.v1+json,application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.oci.image.manifest.v1+json,application/vnd.docker.distribution.manifest.v2+json"

man="$(get -H "Accept: $accept" "$api/v2/$repo/manifests/$tag")"
digest="$(python3 -Ic 'import sys,json;m=json.load(sys.stdin);a=sys.argv[1]
print(next(x["digest"] for x in m["manifests"] if x.get("platform",{}).get("architecture")==a) if "manifests" in m else "")' "$arch" <<<"$man")"
[ -n "$digest" ] && man="$(get -H "Accept: $accept" "$api/v2/$repo/manifests/$digest")"

mkdir -p "$dest"
python3 -Ic 'import sys,json;m=json.load(sys.stdin);print(m["config"]["digest"])
[print(l["digest"], l["mediaType"]) for l in m["layers"]]' <<<"$man" | {
  read -r config
  while read -r layer mtype; do
    echo "layer $layer $mtype" >&2
    # Home Assistant's own ghcr base images ship zstd layers; this host has no zstd binary.
    case "$mtype" in
      *zstd) command -v zstd >/dev/null || { echo "zstd layer and no zstd binary: $layer" >&2; exit 1; }; z=--zstd ;;
      *gzip) z=-z ;;
      *) z= ;;
    esac
    # Non-root extraction cannot mknod or chown; any other tar error is shown.
    get "$api/v2/$repo/blobs/$layer" | tar -x $z -C "$dest" --no-same-owner 2>&1 \
      | grep -vE 'Cannot (mknod|change ownership)|Exiting with failure' >&2 || true
    # OCI whiteouts: .wh.<name> deletes <name> from the layers below. Opaque markers
    # (.wh..wh..opq) are only removed, not applied: rare in app images, and harmless for curl tests.
    find "$dest" -name '.wh.*' | while read -r wh; do
      rm -rf "$(dirname "$wh")/$(basename "$wh" | sed 's/^\.wh\.//')" "$wh"
    done
  done
  get "$api/v2/$repo/blobs/$config" | python3 -Ic 'import sys,json;c=json.load(sys.stdin)["config"]
for k in ("Env","Entrypoint","Cmd","WorkingDir","User"): print(k, c.get(k))'
}
