#!/usr/bin/env bash
set -euo pipefail

####################
# helper functions #
####################
log() { [[ ${VERBOSE:-false} == true ]] && echo "$*"; }
die() { echo "ERROR: $*" >&2; exit 1; }
is_installed() { for c; do command -v "$c" &>/dev/null || return 1; done; return 0; }

#########################
# detect package system #
#########################
if command -v apk &>/dev/null; then
  PM=apk
  INSTALL="apk add --no-cache"
  UPDATE="apk update -q"
elif command -v apt-get &>/dev/null; then
  PM=apt
  INSTALL="apt-get -yqq install --no-install-recommends"
  UPDATE="apt-get -qq update"
elif command -v pacman &>/dev/null; then
  PM=pacman
  INSTALL="pacman -Sy --noconfirm"
  UPDATE="pacman -Sy --noconfirm"
else
  die "No supported package manager found"
fi
log "Detected package manager: $PM"

############################
# static base dependencies #
############################
pkgs_common=(jq curl ca-certificates)

#########################################
# map  tool → packages (per PM) in YAML #
#########################################
declare -A APT=(
  [nginx]="nginx"
  [mount]="exfat-fuse ntfs-3g squashfs-tools util-linux"
  [ping]="iputils-ping"
  [nmap]="nmap"
  [cifs]="cifs-utils keyutils"
  [smbclient]="samba smbclient ntfs-3g"
  [dos2unix]="dos2unix"
  [openvpn]="openvpn coreutils"
  [jq]="jq"
  [yamllint]="yamllint"
  [git]="git"
  [sponge]="moreutils"
  [sqlite3]="sqlite3"
  [pip]="python3-pip"
  [wget]="wget"
)
declare -A APK=(
  [nginx]="nginx"
  [mount]="exfatprogs ntfs-3g squashfs-tools fuse lsblk"
  [ping]="iputils"
  [nmap]="nmap nmap-scripts"
  [cifs]="cifs-utils keyutils"
  [smbclient]="samba samba-client ntfs-3g"
  [dos2unix]="dos2unix"
  [openvpn]="openvpn coreutils"
  [jq]="jq"
  [yamllint]="yamllint"
  [git]="git"
  [sponge]="moreutils"
  [sqlite3]="sqlite"
  [pip]="py3-pip"
  [wget]="wget"
)
declare -A PACMAN=(
  [nginx]="nginx"
  [mount]="exfat-utils ntfs-3g squashfs-tools util-linux fuse2fs"
  [ping]="iputils"
  [nmap]="nmap"
  [cifs]="cifs-utils keyutils"
  [smbclient]="samba smbclient"
  [dos2unix]="dos2unix"
  [openvpn]="openvpn coreutils"
  [jq]="jq"
  [yamllint]="yamllint"
  [git]="git"
  [sponge]="moreutils"
  [sqlite3]="sqlite"
  [pip]="python-pip"
  [wget]="wget"
)

########################
# scan service scripts #
########################
dirs=(/etc/cont-init.d /etc/services.d)
declare -a wants=()
for d in "${dirs[@]}"; do
  [[ -d $d ]] || continue
  mapfile -d '' all_files < <(find "$d" -type f -print0)
  [[ ${#all_files[@]} -eq 0 ]] && continue
  for cmd in "${!APT[@]}"; do
    grep -qF "$cmd" "${all_files[@]}" && wants+=("$cmd")
  done
done

######################
# build package list #
######################
declare -a pkgs=("${pkgs_common[@]}")
for cmd in $(printf '%s\n' "${wants[@]}" | sort -u); do
  is_installed "$cmd" && continue
  case "$PM" in
    apt)    pkgstr="${APT[$cmd]}";;
    apk)    pkgstr="${APK[$cmd]}";;
    pacman) pkgstr="${PACMAN[$cmd]}";;
  esac
  # FIX: explicit if, safe splitting
  if [[ -n $pkgstr ]]; then
    read -r -a pkgarr <<< "$pkgstr"
    pkgs+=("${pkgarr[@]}")
  else
    log "No package mapping for $cmd on $PM"
  fi
done
# de-dup final list
mapfile -t pkgs < <(printf '%s\n' "${pkgs[@]}" | sort -u)

if [[ -d /etc/nginx ]]; then mv /etc/nginx /etc/nginx2; fi

################
# installation #
################
log "Updating package index…"
$UPDATE

log "Installing packages: ${pkgs[*]}"
for p in "${pkgs[@]}"; do
  log " ↳ $p"
  if ! $INSTALL "$p" &>/dev/null; then
    log " ⚠️  $p not found"
    touch /ERROR
  fi
done

if [[ -d /etc/nginx2 ]]; then
    log "replace nginx2"
    rm -rf /etc/nginx
    mv /etc/nginx2 /etc/nginx
    mkdir -p /var/log/nginx
    touch /var/log/nginx/error.log
fi

[[ $PM == apt ]] && apt-get clean -qq

############
#  extras  #
############
if ! command -v micro &>/dev/null; then
  log "Installing micro text editor"
  curl https://getmic.ro | bash || true
  mv micro /usr/bin || true
  micro -plugin install bounce || true
  micro -plugin install filemanager || true
fi

for files in "/etc/services.d" "/etc/cont-init.d"; do
  [[ -d $files ]] || continue

  if grep -q -rnw "$files/" -e 'bashio' && [[ ! -f "/usr/bin/bashio" ]]; then
    log "install bashio"
    BASHIO_VERSION="0.14.3"
    mkdir -p /tmp/bashio
    curl -f -L -s -S "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" | tar -xzf - --strip 1 -C /tmp/bashio
    mv /tmp/bashio/lib /usr/lib/bashio
    ln -s /usr/lib/bashio/bashio /usr/bin/bashio
    rm -rf /tmp/bashio
  fi

  COMMAND="lastversion"
  if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
    log "install $COMMAND"
    pip install $COMMAND
  fi

  # Tempio
  if grep -q -rnw "$files/" -e 'tempio' && [ ! -f "/usr/bin/tempio" ]; then
    [ "$VERBOSE" = true ] && echo "install tempio"
    TEMPIO_VERSION="2021.09.0"
    BUILD_ARCH="$(bashio::info.arch)"
    curl -f -L -f -s -o /usr/bin/tempio "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}"
    chmod a+x /usr/bin/tempio
  fi

  COMMAND="mustache"
  if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
    log "$COMMAND required"
    case "$PM" in
      apk)
        apk add --no-cache go npm &&
        apk upgrade --no-cache &&
        apk add --no-cache --virtual .build-deps build-base git go &&
        go get -u github.com/quantumew/mustache-cli &&
        cp "$GOPATH"/bin/* /usr/bin/ &&
        rm -rf "$GOPATH" /var/cache/apk/* /tmp/src &&
        apk del .build-deps xz build-base
        ;;
      apt)
        apt-get update &&
        apt-get install -yqq go npm node-mustache
        ;;
    esac
  fi
done

[[ -f /ERROR ]] && die "Some packages failed to install"
