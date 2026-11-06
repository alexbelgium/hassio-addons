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
print(next(x["digest"] for x in m["manifests"] if x.get("platform",{}).get("os")=="linux" and x["platform"].get("architecture")==a) if "manifests" in m else "")' "$arch" <<<"$man")"
[ -n "$digest" ] && man="$(get -H "Accept: $accept" "$api/v2/$repo/manifests/$digest")"

# A whiteout in a layer deletes paths under dest: never unpack over something that is already there.
mkdir -p "$dest"
[ -z "$(ls -A "$dest")" ] || { echo "dest is not empty: $dest" >&2; exit 1; }
blob="$dest.blob"; errs="$dest.tar-errors"; trap 'rm -f "$blob" "$errs"' EXIT
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
    # Download to a file first, so a failed or truncated download stops the script.
    get -o "$blob" "$api/v2/$repo/blobs/$layer" || { echo "layer download failed: $layer" >&2; exit 1; }
    # Opaque whiteout (<dir>/.wh..wh..opq): <dir> keeps only this layer's files, so empty it first.
    tar -t $z -f "$blob" | sed -nE 's#^(\./)?(.*/)?\.wh\.\.wh\.\.opq$#\2#p' | while read -r d; do
      case "/$d" in */../*) echo "bad opaque whiteout path: $d" >&2; exit 1 ;; esac
      if [ -d "$dest/$d" ] && [ ! -L "$dest/${d%/}" ]; then
        find "$dest/$d" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
      fi
    done
    # Non-root extraction cannot mknod or chown; tolerate only those, stop on any other tar error.
    if ! tar -x $z -f "$blob" -C "$dest" --no-same-owner 2>"$errs"; then
      if grep -vqE 'Cannot (mknod|change ownership)|Exiting with failure' "$errs"; then
        cat "$errs" >&2; echo "layer extraction failed: $layer" >&2; exit 1
      fi
    fi
    # Plain whiteouts: .wh.<name> deletes <name> from the layers below.
    find "$dest" -name '.wh..wh..opq' -delete
    find "$dest" -name '.wh.*' | while read -r wh; do
      rm -rf "$(dirname "$wh")/$(basename "$wh" | sed 's/^\.wh\.//')" "$wh"
    done
  done
  get "$api/v2/$repo/blobs/$config" | python3 -Ic 'import sys,json;c=json.load(sys.stdin)["config"]
for k in ("Env","Entrypoint","Cmd","WorkingDir","User"): print(k, c.get(k))'
}
