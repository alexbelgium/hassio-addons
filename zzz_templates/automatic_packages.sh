#!/bin/bash
echo "AUTOMATIC PACKAGES SELECTION"
set +u

##################
# INIT VARIABLES #
##################

PACKAGES=${PACKAGES:-""}
PACKMANAGER="apk"

############################
# CHECK WHICH BASE IS USED #
############################

if [[ "$(apk -h 2>/dev/null)" ]]; then
# If apk based
PACKMANAGER="apk"
    echo "yes"
    echo "yes"
else
# If apt-get based
PACKMANAGER="apt"
    echo "no"
    echo "no"
fi

###################
# DEFINE PACKAGES #
###################

# ADD GENERAL ELEMENTS
######################

PACKAGES="$PACKAGES jq curl"

# FOR EACH SCRIPT, SELECT PACKAGES
##################################

if ls /etc/cont-init.d/*smb_mounts* 1> /dev/null 2>&1; then
[ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES cifs-utils keyutils samba samba-client"
[ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES cifs-utils keyutils samba smbclient"
fi

if ls /etc/cont-init.d/*vpn* 1> /dev/null 2>&1; then
[ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES coreutils openvpn"
[ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES coreutils openvpn"
fi

if ls /etc/cont-init.d/*global_var* 1> /dev/null 2>&1; then
[ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES jq"
[ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES jq"
fi

if ls /etc/cont-init.d/*yaml* 1> /dev/null 2>&1; then
[ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES yamllint"
[ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES yamllint"
fi

if ls /etc/*nginx* 1> /dev/null 2>&1; then
[ $PACKMANAGER = "apk" ] && PACKAGES="$PACKAGES nginx"
[ $PACKMANAGER = "apt" ] && PACKAGES="$PACKAGES nginx"
fi
