#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#           _.------.
#       _.-`    ('>.-`"""-.port
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

# Install locales
RUN apt-get update && apt-get install --no-install-recommends -y locales && locale-gen en_US.UTF-8
ENV DEBIAN_FRONTEND="noninteractive" \
    BIRDNET_USER="pi" \
    USER="pi" \
    PUID=1000 \
    PGID=1000 \
    HOME="/home/pi" \
    XDG_RUNTIME_DIR="/run/user/1000" \
    PYTHON_VIRTUAL_ENV="/home/pi/BirdNET-Pi/birdnet/bin/python3" \
    my_dir=/home/pi/BirdNET-Pi/scripts \
    LANGUAGE=en_US:en

# Global LSIO modifications
COPY ha_lsio.sh /ha_lsio.sh
ARG CONFIGLOCATION="/config"
RUN chmod 744 /ha_lsio.sh && if grep -qr "lsio" /etc; then /ha_lsio.sh "$CONFIGLOCATION"; fi && rm /ha_lsio.sh

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3015,SC2016
# Add rootfs
COPY rootfs/ /
RUN find . -type f \( -name "*.sh" -o -name "run" -o -name "finish" \) -print -exec chmod +x {} \;
RUN \
    # Install dependencies
    echo "Install dependencies" && \
    apt-get update -y && apt-get install curl gcc python3-dev git jq sudo php-mbstring procps -y && \
    \
    # Correct for systemctl
    mkdir -p /helpers && \
    curl -f -L -s -S https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -o /helpers/systemctl && \
    cp -rf /helpers/systemctl /bin/systemctl && \
    chmod a+x /bin/systemctl && \
    \
    # Correct for journalctl
    curl -f -L -s -S https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/journalctl3.py -o /helpers/journalctl && \
    cp -rf /helpers/journalctl /bin/journalctl && \
    chmod a+x /bin/journalctl && \
    \
    # Change user to pi and create /home/pi
    echo "setting users" && \
    if id abc >/dev/null 2>&1; then groupmod -o -g 101 abc && usermod -o -u 101 abc; fi && \
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
    curl -f -L -s -S "https://raw.githubusercontent.com/alexbelgium/BirdNET-Pi/main/newinstaller.sh" -o /newinstaller.sh && \
    chmod 777 /newinstaller.sh && \
    \
    # Modify installer
    ##################
    # Use my repository
    cd / && \
    sed -i "s|Nachtzuster|alexbelgium|g" newinstaller.sh && \
    cd /home/pi && \
    # Install open PR
    chmod +x /helpers/merge_open_prs.sh && \
    # Avoid rebooting at end of installation
    sed -i "/reboot/d" /newinstaller.sh && \
    # Use apt-get as without user action
    sed -i "s|apt |apt-get |g" /newinstaller.sh && \
    # Ensure chmod
    sed -i "/git clone/a chown -R 1000:1000 $HOME" /newinstaller.sh && \
    sed -i "/git clone/a chmod 777 \$HOME/BirdNET-Pi/scripts/*.sh" /newinstaller.sh && \
    # Disable datetimectl
    sed -i '/git clone/a sed -i "/CURRENT_TIMEZONE/s/$/ || true/" $HOME/BirdNET-Pi/scripts/install_birdnet.sh' /newinstaller.sh && \
    # Remove all instances of sudo from the newinstaller
    sed -i -e "s|== 0|== 7|g" -e "s|sudo -n true|true|g" -e "s|sudo -K|true|g" /newinstaller.sh && \
    # Merge all PR
    sed -i '/git clone/a sed -i "/exit installation if anything fails/a cd $HOME/BirdNET-Pi \&\& /./helpers/merge_open_prs.sh" $HOME/BirdNET-Pi/scripts/install_birdnet.sh' /newinstaller.sh && \
    \
    # Execute installer
    /./newinstaller.sh && \
    \
    # Remove sudo from the installed BirdNET-Pi scripts.
    # Inside the container everything already runs with the privileges it needs
    # (root during init, user "pi" for the services), so "sudo" is never required.
    # Leaving it in breaks any script invoked by a user that is not in sudoers -
    # e.g. php-fpm's "caddy" user driving the WebUI System Controls, or the "abc"
    # user - which is what prevented BirdNET-Pi from working in standalone
    # (no-Supervisor) mode. This must run AFTER the installer has cloned the repo;
    # the previous build-time hook ran before the clone and was therefore a no-op.
    for file in $(grep -srlF "sudo " "$HOME/BirdNET-Pi/scripts"); do sed -i "s|sudo ||g" "$file"; done && \
    \
    # Install dateparser and resampy, upgrade numpy
    $PYTHON_VIRTUAL_ENV /usr/bin/pip3 install dateparser resampy && \
    \
    # Adapt for lsio usage of /app
    if [ -d /app ]; then rm -r /app; fi && \
    ln -s /home/"$USER" /app && \
    chown -R "$USER":"$USER" /home/"$USER" /app && \
    \
    # Give access to caddy for files owned by the user, to allow files modification
    groupmod -o -g 1000 caddy && usermod -o -u 1000 caddy && \
    \
    # Give access to audio devices
    usermod -aG audio "$USER" && \
    \
    # Ensure always pi is used
    grep -srl "/etc/passwd" "$HOME/BirdNET-Pi/" | while IFS= read -r file; do sed -i "s=/etc/passwd=/etc/passwd | head -1=g" "$file"; done && \
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

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES="00-local_mounts.sh 00-smb_mounts.sh"

# Automatic modules download
COPY ha_automodules.sh /ha_automodules.sh
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="alsa-utils libasound2-plugins mosquitto-clients file pulseaudio"

# Automatic apps & bashio
COPY ha_autoapps.sh /ha_autoapps.sh
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Add entrypoint
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
COPY ha_entrypoint.sh /ha_entrypoint.sh
RUN chmod 777 /ha_entrypoint.sh

# Install bashio
COPY bashio-standalone.sh /usr/local/lib/bashio-standalone.sh
RUN chmod 0755 /usr/local/lib/bashio-standalone.sh

# Avoid config.yaml interference
WORKDIR /config
#ENTRYPOINT ["/lib/systemd/systemd"]
#ENTRYPOINT [ "/usr/bin/env" ]
#CMD [ "/ha_entrypoint.sh" ]
#SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Allow a dockerfile independent from HA
EXPOSE 80
RUN mkdir -p /data /config

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
ENV BUILD_VERSION="${BUILD_VERSION}"
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

# Avoid spamming logs
# hadolint ignore=SC2016
RUN \
    # Handle Apache configuration
    if [ -d /etc/apache2/sites-available ]; then \
        for file in /etc/apache2/sites-*/*.conf; do \
            sed -i '/<VirtualHost/a \ \n    # Match requests with the custom User-Agent "HealthCheck" \n    SetEnvIf User-Agent "HealthCheck" dontlog \n    # Exclude matching requests from access logs \n    CustomLog ${APACHE_LOG_DIR}/access.log combined env=!dontlog' "$file"; \
        done; \
    fi && \
    \
    # Handle Nginx configuration
    if [ -f /etc/nginx/nginx.conf ]; then \
        awk '/http \{/{print; print "map $http_user_agent $dontlog {\n  default 0;\n  \"~*HealthCheck\" 1;\n}\naccess_log /var/log/nginx/access.log combined if=$dontlog;"; next}1' /etc/nginx/nginx.conf > /etc/nginx/nginx.conf.new && \
        mv /etc/nginx/nginx.conf.new /etc/nginx/nginx.conf; \
    fi

# Health-check the actual WebUI port. In standalone Docker (no Supervisor) nginx
# is disabled and Caddy serves the UI on 8081; nothing listens on port 80 when
# ssl=false, which made the container report "unhealthy" even though it worked.
# Select https when ssl is enabled (92-ssl.sh switches Caddy to https://:8081),
# and use -k since the probe hits 127.0.0.1 rather than the cert's real name.
# Note: the shell form's CMD runs under /bin/sh (dash here, not bash), so this
# avoids "&>" (a bash-only redirection dash parses as background + no-op,
# which silently discarded curl's exit status and made the check always pass).
ENV HEALTH_PORT="8081" \
    HEALTH_URL=""
HEALTHCHECK \
    --interval=5s \
    --retries=5 \
    --start-period=30s \
    --timeout=25s \
    CMD scheme=http; case "${ssl:-false}" in true|TRUE|True|1|yes|YES|Yes|on|ON|On) scheme=https ;; esac; curl -A "HealthCheck: Docker/1.0" -s -k -f "${scheme}://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" >/dev/null 2>&1 || exit 1
