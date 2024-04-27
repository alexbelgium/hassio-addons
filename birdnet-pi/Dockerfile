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
    apt-get update -y && apt-get install curl gcc python3-dev git jq sudo php-mbstring procps -y && \
    \
    # Correct for systemctl
    curl -f -L -s -S https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -o /bin/systemctl && \
    chmod a+x /bin/systemctl && \
    curl -f -L -s -S https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/journalctl3.py -o /bin/journalctl && \
    chmod a+x /bin/journalctl && \
    \
    # Change user to pi and create /home/pi
    echo "setting users" && \
    groupmod -o -g 101 abc && usermod -o -u 101 abc && \
    groupadd --non-unique -g 1000 "$USER" && \
    useradd --non-unique --uid 1000 --gid 1000 -m "$USER" && \
    \
    # Ensure permissions
    echo "setting permissions" && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/"$USER"/.config/matplotlib && \
    chown -R "$USER":"$USER" /home/"$USER" && \
    git config --global --add safe.directory '*' && \
    \
    # Download installer
    curl -f -L -s -S "https://raw.githubusercontent.com/Nachtzuster/BirdNET-Pi/main/newinstaller.sh" -o /newinstaller.sh && \
    chmod 777 /newinstaller.sh && \
    \
    # Use installer to modify other scripts
    #######################################
    # Define file
    sed -i "1a /./newinstallermod.sh" /newinstaller.sh && \
    echo '#!/bin/bash' >> /newinstallermod.sh && \
    # Remove all instances of sudo from all other scripts
    echo 'for file in $(grep -srl "sudo" $HOME/BirdNET-Pi/scripts); do sed -i "s|sudo ||" "$file"; done' >> /newinstallermod.sh && \
    echo 'for file in $(grep -srl "my_dir" $HOME/BirdNET-Pi/scripts); do sed -i "s|\$my_dir|/config|" "$file"; done' >> /newinstallermod.sh && \
    # Disable pulseaudio
    echo 'for file in $(grep -srl "pulseaudio --start" $HOME/BirdNET-Pi/scripts); do sed -i "/pulseaudio --start/d" "$file"; done' >> /newinstallermod.sh && \
    # Set permission
    chmod +x /newinstallermod.sh && \
    \
    # Modify installer
    ##################
    # Avoid rebooting at end of installation
    sed -i "/reboot/d" /newinstaller.sh && \
    # Use apt-get as without user action
    sed -i "s|apt |apt-get |g" /newinstaller.sh && \
    # Ensure chmod
    sed -i "/git clone/a chown -R 1000:1000 $HOME" /newinstaller.sh && \
    # Remove all instances of sudo from the newinstaller
    sed -i -e "s|== 0|== 7|g" -e "s|sudo -n true|true|g" -e "s|sudo -K|true|g" /newinstaller.sh && \
    \
    # Execute installer
    /./newinstaller.sh && \
    \
    # Adapt for lsio usage of /app
    if [ -d /app ]; then rm -r /app; fi && \
    ln -s /home/"$USER" /app && \
    chown -R "$USER":"$USER" /home/"$USER" /app && \
    \
    # Cleanup
    apt-get clean all && \
    rm -rf /var/lib/apt/lists/*

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
ENV PACKAGES="alsa-utils libasound2-plugins"

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
