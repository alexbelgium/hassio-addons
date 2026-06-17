#!/bin/sh
# shellcheck disable=SC2015
set -e

##############################
# Automatic apps download #
##############################

PACKAGES="$1"
echo "To install : $PACKAGES"

apt_has_sources() {
    [ -d /etc/apt ] || return 1
    find /etc/apt -type f \( -name "sources.list" -o -name "*.list" -o -name "*.sources" \) \
        -exec grep -Ehs '^[[:space:]]*(deb|Types:[[:space:]]*deb)' {} \; | grep -q .
}

restore_apt_sources_if_missing() {
    command -v apt-get > /dev/null 2> /dev/null || return 0
    apt_has_sources && return 0

    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
    fi

    codename="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
    if [ -z "$codename" ]; then
        echo "Error: apt sources are missing and OS codename could not be detected" >&2
        exit 1
    fi

    mkdir -p /etc/apt
    case "${ID:-}" in
        ubuntu)
            arch="$(dpkg --print-architecture 2> /dev/null || true)"
            if [ "$arch" = "amd64" ] || [ "$arch" = "i386" ]; then
                mirror="http://archive.ubuntu.com/ubuntu"
                security_mirror="http://security.ubuntu.com/ubuntu"
            else
                mirror="http://ports.ubuntu.com/ubuntu-ports"
                security_mirror="$mirror"
            fi
            cat > /etc/apt/sources.list <<EOF2
deb ${mirror} ${codename} main restricted universe multiverse
deb ${mirror} ${codename}-updates main restricted universe multiverse
deb ${security_mirror} ${codename}-security main restricted universe multiverse
EOF2
            ;;
        debian)
            cat > /etc/apt/sources.list <<EOF2
deb http://deb.debian.org/debian ${codename} main contrib non-free non-free-firmware
deb http://deb.debian.org/debian ${codename}-updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security ${codename}-security main contrib non-free non-free-firmware
EOF2
            ;;
        *)
            echo "Error: apt sources are missing for unsupported OS '${ID:-unknown}'" >&2
            exit 1
            ;;
    esac
}

restore_apt_sources_if_missing
rm -f /ERROR

# Install bash if needed
if ! command -v bash > /dev/null 2> /dev/null; then
    (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) > /dev/null
fi

# Install curl if needed
if ! command -v curl > /dev/null 2> /dev/null; then
    (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) > /dev/null
fi

# Call apps installer script if needed
curl -f -L -S "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automatic_packages.sh" --output /ha_automatic_packages.sh
chmod 755 /ha_automatic_packages.sh
eval /./ha_automatic_packages.sh "${PACKAGES:-}"

# Clean
rm /ha_automatic_packages.sh
