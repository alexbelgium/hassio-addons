#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#           _.------.
#       _.-`    ('>.-`"""-.
# '.--'`       _'`   _ .--.)
#    -'         '-.-';`   `
#    ' -      _.'  ``'--.
#        '---`    .-'""`
#               /`
#=== Home Assistant Addon ===#

#################
# 1 Build Image #
#################

ARG BUILD_VERSION
ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV DEBIAN_FRONTEND="noninteractive" \
    BIRDNET_USER="pi" \
    USER="pi" \
    PUID=1000 \
    PGID=1000 \
    HOME="/home/pi" \
    XDG_RUNTIME_DIR="/run/user/1000" \
    PYTHON_VIRTUAL_ENV="/home/pi/BirdNET-Pi/birdnet/bin/python3"

# hadolint ignore=DL3015,SC2016
RUN \
    # Install dependencies
    echo "Install dependencies" && \
    apt-get update -y && apt-get install gcc python3-dev git jq sudo -y && \
    \
    # Change user to pi and create /home/pi
    echo "setting users" && \
    groupadd --non-unique -g 1000 pi && \
    useradd --non-unique --uid 1000 --gid 1000 -m pi && \
    \
    # Ensure permissions
    echo "setting permissions" && \
    echo "pi ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/pi/.config/matplotlib && \
    chown -R 1000:1000 /home/pi && \
    \
    # Download installer
    curl -f -L -s -S "https://raw.githubusercontent.com/Nachtzuster/BirdNET-Pi/main/newinstaller.sh" -o /newinstaller.sh && \
    chmod 777 /newinstaller.sh && \
    \
    # Modify installer
    # Avoid rebooting at end of installation
    sed -i "/reboot/d" /newinstaller.sh && \
    # Use apt-get as without user action
    sed -i "s|apt |apt-get |g" /newinstaller.sh && \
    # Remove all instances of sudo from the newinstaller
    sed -i -e "s|== 0|== 7|g" -e "s|sudo -n true|true|g" -e "s|sudo -K|true|g" /newinstaller.sh && \
    # Remove all instances of sudo from all other scripts
    sed -i '1a for file in $(grep -srl "sudo" $HOME/BirdNET-Pi/scripts); do sed -i "s|sudo ||" "$file"; done' /newinstaller.sh && \
    sed -i '1a for file in $(grep -srl "my_dir" $HOME/BirdNET-Pi/scripts); do sed -i "s|\$my_dir|/config|" "$file"; done' /newinstaller.sh && \
    sed -i '1a for file in $(grep -srl "install_services.sh" $HOME/BirdNET-Pi/scripts); do sed -i "/install_services.sh/c ./install_services.sh" "$file"; done' /newinstaller.sh && \
    # Avoid systemctl
    sed -i '/git clone/a sed -i "s|systemctl enable|#systemctl enable|g" "$HOME"/BirdNET-Pi/scripts/install_services.sh' /newinstaller.sh && \
    \
    # Execute installer
    /./newinstaller.sh && \
    \
    # Adapt for lsio usage of /app
    if [ -d /app ]; then rm -r /app; fi && \
    ln -s /home/pi /app && \
    chown -R 1000:1000 /home/pi /app

#USER pi
#WORKDIR /app
#RUN export DEBIAN_FRONTEND noninteractive && \
#    export BIRDNET_USER="pi" && \
#    export USER="pi" && \
#    export HOME="/app" && \
#    echo "HOME is $HOME" && \
#    ls -l /app && \
#    sudo chown -R pi:pi /app && \
#    /./newinstaller.sh
#USER root
    #sudo -E -u birdnet -s /bin/bash -c "/newinstaller.sh"
    # Correct script
    #sed -i "s|== 0|== 7|g" /newinstaller.sh && \
    #sed -i "s|sudo -n true|true|g" /newinstaller.sh && \
    #sed -i "s|sudo -K|true|g" /newinstaller.sh && \
    #for file in $(grep -srl "sudo" $HOME/BirdNET-Pi/scripts); do \sed -i "s|sudo ||" "$file"; done && \
    #/./newinstaller.sh
    # Correct for absence of sudo
    #sudo -E -u birdnet -s /bin/bash -c "/newinstaller.sh"

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES="00-local_mounts.sh 00-smb_mounts.sh"

# Automatic modules download
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" "/ha_automodules.sh"
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="alsa-utils libasound2-plugins nginx"

# Automatic apps & bashio
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" "/ha_autoapps.sh"
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Add entrypoint
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"

# Entrypoint modifications
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint_modif.sh" "/ha_entrypoint_modif.sh"
RUN chmod 777 /ha_entrypoint.sh /ha_entrypoint_modif.sh && /ha_entrypoint_modif.sh && rm /ha_entrypoint_modif.sh

# Avoid config.yaml interference
WORKDIR /config
#ENTRYPOINT ["/lib/systemd/systemd"]
#ENTRYPOINT [ "/usr/bin/env" ]
#CMD [ "/ha_entrypoint.sh" ]
#SHELL ["/bin/bash", "-o", "pipefail", "-c"]

############
# 5 Labels #
############

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/alexbelgium" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

#################
# 6 Healthcheck #
#################

ENV HEALTH_PORT="80" \
    HEALTH_URL=""
HEALTHCHECK \
    --interval=5s \
    --retries=5 \
    --start-period=30s \
    --timeout=25s \
    CMD curl --fail "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" &>/dev/null || exit 1
