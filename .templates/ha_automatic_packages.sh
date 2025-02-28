#!/bin/bash
set -e

########
# INIT #
########

#Verbose or not
VERBOSE=false
#Avoid fails on non declared variables
set +u 2>/dev/null || true
#If no packages, empty
PACKAGES="${*:-}"
#Avoids messages if non interactive
(echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections) &>/dev/null || true

[ "$VERBOSE" = true ] && echo "ENV : $PACKAGES"

############################
# CHECK WHICH BASE IS USED #
############################

if command -v "apk" &>/dev/null; then
    # If apk based
    [ "$VERBOSE" = true ] && echo "apk based"
    PACKMANAGER="apk"
elif command -v "apt" &>/dev/null; then
    # If apt-get based
    [ "$VERBOSE" = true ] && echo "apt based"
    PACKMANAGER="apt"
elif command -v "pacman" &>/dev/null; then
    # If apt-get based
    [ "$VERBOSE" = true ] && echo "pacman based"
    PACKMANAGER="pacman"
fi

###################
# DEFINE PACKAGES #
###################

# ADD GENERAL ELEMENTS
######################

PACKAGES="$PACKAGES jq curl vim ca-certificates"

# FOR EACH SCRIPT, SELECT PACKAGES
##################################

# Scripts
for files in "/etc/cont-init.d" "/etc/services.d"; do
    # Next directory if does not exists
    if ! ls $files 1>/dev/null 2>&1; then continue; fi

    # Test each possible command
    COMMAND="nginx"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES nginx"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES nginx"
        [ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES nginx"
        if ls /etc/nginx 1>/dev/null 2>&1; then mv /etc/nginx /etc/nginx2; fi
    fi

    COMMAND="mount"
    if grep -q -rnw "$files/" -e "$COMMAND"; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES exfatprogs ntfs-3g ntfs-3g-progs squashfs-tools fuse lsblk"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES exfat* ntfs* squashfs-tools util-linux"
        #[ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES ntfs-3g"
    fi

    COMMAND="ping"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES iputils"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES iputils-ping"
        #[ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES iputils"
    fi

    COMMAND="nmap"
    if grep -q -rnw "$files/" -e "$COMMAND"; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES nmap nmap-scripts"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES nmap"
        #[ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES iputils"
    fi

    COMMAND="cifs"
    if grep -q -rnw "$files/" -e "$COMMAND"; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES cifs-utils keyutils"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES cifs-utils keyutils"
        [ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES cifs-utils keyutils"
    fi

    COMMAND="smbclient"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES samba samba-client ntfs-3g"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES samba smbclient ntfs-3g"
        [ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES samba smbclient"
    fi

    COMMAND="dos2unix"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES dos2unix"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES dos2unix"
        [ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES dos2unix"
    fi

    COMMAND="openvpn"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES coreutils openvpn"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES coreutils openvpn"
        [ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES coreutils openvpn"
    fi

    COMMAND="jq"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES jq"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES jq"
        [ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES jq"
    fi

    COMMAND="yamllint"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES yamllint"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES yamllint"
        [ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES yamllint"
    fi

    COMMAND="git"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES git"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES git"
        [ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES git"
    fi

    COMMAND="sponge"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES moreutils"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES moreutils"
        [ "$PACKMANAGER" = "pacman " ] && PACKAGES="$PACKAGES moreutils"
    fi

    COMMAND="sqlite3"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES sqlite"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES sqlite3"
        [ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES sqlite3"
    fi

    COMMAND="pip"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES py3-pip"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES pip"
        [ "$PACKMANAGER" = "pacman" ] && PACKAGES="$PACKAGES pip"
    fi

    COMMAND="wget"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && PACKAGES="$PACKAGES wget"
        [ "$PACKMANAGER" = "apt" ] && PACKAGES="$PACKAGES wget"
        [ "$PACKMANAGER" = "wget" ] && PACKAGES="$PACKAGES wget"
    fi

done

####################
# INSTALL ELEMENTS #
####################

# Install apps
[ "$VERBOSE" = true ] && echo "installing packages $PACKAGES"
if [ "$PACKMANAGER" = "apt" ]; then apt-get update >/dev/null; fi
if [ "$PACKMANAGER" = "pacman" ]; then pacman -Sy >/dev/null; fi

# Install apps one by one to allow failures
# shellcheck disable=SC2086
for packagestoinstall in $PACKAGES; do
    [ "$VERBOSE" = true ] && echo "... $packagestoinstall"
    if [ "$PACKMANAGER" = "apk" ]; then
        apk add --no-cache "$packagestoinstall" &>/dev/null || (echo "Error : $packagestoinstall not found" && touch /ERROR)
    elif [ "$PACKMANAGER" = "apt" ]; then
        apt-get install -yqq --no-install-recommends "$packagestoinstall" &>/dev/null || (echo "Error : $packagestoinstall not found" && touch /ERROR)
    elif [ "$PACKMANAGER" = "pacman" ]; then
        pacman --noconfirm -S "$packagestoinstall" &>/dev/null || (echo "Error : $packagestoinstall not found" && touch /ERROR)
    fi
    [ "$VERBOSE" = true ] && echo "... $packagestoinstall done"
done

# Clean after install
[ "$VERBOSE" = true ] && echo "Cleaning apt cache"
if [ "$PACKMANAGER" = "apt" ]; then apt-get clean >/dev/null; fi

# Replace nginx if installed
if ls /etc/nginx2 1>/dev/null 2>&1; then
    [ "$VERBOSE" = true ] && echo "replace nginx2"
    rm -r /etc/nginx
    mv /etc/nginx2 /etc/nginx
    mkdir -p /var/log/nginx
    touch /var/log/nginx/error.log
fi

#######################
# INSTALL MANUAL APPS #
#######################

# Install micro texteditor
curl https://getmic.ro | bash || true
mv micro /usr/bin || true
micro -plugin install bounce || true
micro -plugin install filemanager || true

for files in "/etc/services.d" "/etc/cont-init.d"; do

    # Next directory if does not exists
    if ! ls $files 1>/dev/null 2>&1; then continue; fi

    # Bashio
    if grep -q -rnw "$files/" -e 'bashio' && [ ! -f "/usr/bin/bashio" ]; then
        [ "$VERBOSE" = true ] && echo "install bashio"
        BASHIO_VERSION="0.14.3"
        mkdir -p /tmp/bashio
        curl -f -L -s -S "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" | tar -xzf - --strip 1 -C /tmp/bashio
        mv /tmp/bashio/lib /usr/lib/bashio
        ln -s /usr/lib/bashio/bashio /usr/bin/bashio
        rm -rf /tmp/bashio
    fi

    # Lastversion
    COMMAND="lastversion"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "install $COMMAND"
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

    # Mustache
    COMMAND="mustache"
    if grep -q -rnw "$files/" -e "$COMMAND" && ! command -v $COMMAND &>/dev/null; then
        [ "$VERBOSE" = true ] && echo "$COMMAND required"
        [ "$PACKMANAGER" = "apk" ] && apk add --no-cache go npm &&
        apk upgrade --no-cache &&
        apk add --no-cache --virtual .build-deps build-base git go &&
        go get -u github.com/quantumew/mustache-cli &&
        cp "$GOPATH"/bin/* /usr/bin/ &&
        rm -rf "$GOPATH" /var/cache/apk/* /tmp/src &&
        apk del .build-deps xz build-base
        [ "$PACKMANAGER" = "apt" ] && apt-get update &&
        apt-get install -yqq go npm node-mustache
    fi

done

if [ -f /ERROR ]; then
    exit 1
fi
