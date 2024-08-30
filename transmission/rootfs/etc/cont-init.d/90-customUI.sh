#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

################
# Alternate UI #
################

CUSTOMUI=$(bashio::config 'customUI')

# Install webui
if bashio::config.has_value 'customUI' && [ ! "$CUSTOMUI" = default ] && [ ! "$CUSTOMUI" = custom ]; then
    # Variables
    bashio::log.info "Alternate UI enabled : $CUSTOMUI. If webui don't work, disable this option"

    # Clean folders
    if [ -d /"$CUSTOMUI" ]; then rm -r /"${CUSTOMUI:?}"; fi
    if [ -f /"$CUSTOMUI" ]; then rm -r /"${CUSTOMUI:?}"; fi

    ### Download WebUI
    case $CUSTOMUI in
        "combustion-release")
            curl -o /tmp/combustion.zip -L "https://github.com/Secretmapper/combustion/archive/release.zip"
            unzip /tmp/combustion.zip -d /
            ;;

        "transmission-web-control")
            curl -f -s -S -J -L -o /release.zip "$(curl -f -s -L https://api.github.com/repos/transmission-web-control/transmission-web-control/releases/latest | grep -o "http.*dist.zip" | head -1)" >/dev/null
            ### Install WebUI
            mkdir -p /transmission-web-control
            unzip -q /release.zip -d /transmission-web-control
            mv /transmission-web-control/dist/* /transmission-web-control
            rm -r /transmission-web-control/dist
            rm /release.zip
            # Enables the original UI button in transmission-web-control
            ln -s /usr/share/transmission/public_html/* /transmission-web-control/ 2>/dev/null || true
            ln -s /usr/share/transmission/public_html/index.html /transmission-web-control/index.original.html
            ;;

        "kettu")
            mkdir -p /kettu && \
                curl -o /tmp/kettu.tar.gz -L "https://github.com/endor/kettu/archive/master.tar.gz"
            tar xf /tmp/kettu.tar.gz -C /kettu --strip-components=1
            ;;

        "flood-for-transmission")
            curl -o /tmp/flood-for-transmission.tar.gz -L "https://github.com/johman10/flood-for-transmission/releases/download/latest/flood-for-transmission.tar.gz"
            tar xf /tmp/flood-for-transmission.tar.gz -C /
            ;;

        "transmissionic")
            TRANSMISSIONIC_VERSION=$(curl -s -L "https://api.github.com/repos/6c65726f79/Transmissionic/releases/latest" | jq -r .tag_name)
            curl -o /tmp/transmissionic.zip -L "https://github.com/6c65726f79/Transmissionic/releases/download/${TRANSMISSIONIC_VERSION}/Transmissionic-webui-${TRANSMISSIONIC_VERSION}.zip"
            unzip /tmp/transmissionic.zip -d /tmp
            mv /tmp/web /transmissionic
            ;;

        **)
            exit 0
            ;;

    esac

    # Define variable
    if cat /etc/services.d/*/*run* &>/dev/null; then sed -i "1a export TRANSMISSION_WEB_HOME=$CUSTOMUI" /etc/services.d/*/*run* 2>/dev/null; fi
    if [ -d /var/run/s6/container_environment ]; then printf "%s" "$CUSTOMUI" > /var/run/s6/container_environment/TRANSMISSION_WEB_HOME; fi
    printf "%s\n" "TRANSMISSION_WEB_HOME=\"$CUSTOMUI\"" >> ~/.bashrc

fi
