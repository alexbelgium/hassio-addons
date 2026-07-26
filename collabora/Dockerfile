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

ARG BUILD_FROM
ARG BUILD_VERSION

###############################################################################
# Get Collabora Online from the official image (BUILD_FROM, see build.json)
#
# Upstream rebuilt collabora/code as a Nix-based distroless image: /bin and
# /sbin are empty, so it can no longer be the base of the add-on itself, as s6,
# bashio and every RUN need a shell. It stays the tracked upstream image, and
# only the Collabora payload is copied out of it onto a Debian runtime.
#
# Copy only what belongs to Collabora. Do NOT copy /etc or /nix: in that image
# /etc/resolv.conf, /etc/hosts, /etc/passwd, /etc/group and /etc/nsswitch.conf
# are symlinks into /nix/store, and importing them breaks DNS resolution and
# wipes the base image users.
###############################################################################
# hadolint ignore=DL3006
FROM ${BUILD_FROM} AS collabora

###############################################################################
# Build the actual add-on on a base that has a shell
###############################################################################
FROM ghcr.io/hassio-addons/debian-base:9.3.0

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

USER root

# Global LSIO modifications
COPY ha_lsio.sh /ha_lsio.sh
ARG CONFIGLOCATION="/data"
RUN chmod 744 /ha_lsio.sh && if grep -qr "lsio" /etc; then /ha_lsio.sh "$CONFIGLOCATION"; fi && rm /ha_lsio.sh

##################
# 3 Install apps #
##################

# Copy local files
COPY rootfs/ /
RUN find . -type f \( -name "*.sh" -o -name "run" -o -name "finish" \) -print -exec chmod +x {} \;

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES=""

# Automatic modules download
COPY ha_automodules.sh /ha_automodules.sh
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
# coolwsd itself only needs glibc/libstdc++ (max GLIBCXX_3.4.22); the office
# engine bundles its own cairo, fontconfig, curl, icu and fonts under
# /opt/collaboraoffice/program. openssl is used to generate the self-signed
# certificate when the ssl option is off, cpio and findutils by the jail setup.
ENV PACKAGES="ca-certificates cpio findutils fontconfig libcap2-bin libstdc++6 openssl tzdata"

# Automatic apps & bashio
COPY ha_autoapps.sh /ha_autoapps.sh
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" || true && rm /ha_autoapps.sh

# Collabora Online payload, taken from the official image. COPY --from keeps the
# numeric ownership, so /opt/cool and /etc/coolwsd arrive already owned by 1001.
COPY --from=collabora /usr/bin/coolwsd /usr/bin/coolforkit-caps /usr/bin/coolforkit-ns /usr/bin/coolmount /usr/bin/
COPY --from=collabora /usr/share/coolwsd /usr/share/coolwsd
COPY --from=collabora /etc/coolwsd /etc/coolwsd
COPY --from=collabora /opt/collaboraoffice /opt/collaboraoffice
COPY --from=collabora /opt/cool /opt/cool

# Recreate the runtime user the official image declares (uid/gid 1001), and the
# per-container state upstream sets up in its own final build stage.
RUN \
    groupadd --gid 1001 cool && \
    useradd --uid 1001 --gid 1001 --no-create-home --home-dir /opt/cool --shell /usr/sbin/nologin cool && \
    mkdir -p /opt/cool/child-roots /opt/cool/cache && \
    chown -R 1001:1001 /opt/cool /etc/coolwsd && \
    chmod 640 /etc/coolwsd/coolwsd.xml && \
    touch /var/log/coolwsd.log && \
    chown 1001:1001 /var/log/coolwsd.log && \
    # the WOPI proof key must be unique per container, not baked into the image
    rm -rf /etc/coolwsd/proof_key* && \
    fc-cache /opt/collaboraoffice/share/fonts/truetype > /dev/null 2>&1 || true

# Fail the build rather than ship an image that cannot start: ha_autoapps.sh is
# invoked with "|| true", and coolwsd comes from an image built against a
# different libc, so both are worth proving here. coolwsd refuses to run as
# root, so this runs it exactly the way 99-run.sh does.
RUN \
    command -v openssl > /dev/null && \
    su -s /bin/bash cool -c "/usr/bin/coolwsd --version"

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

WORKDIR /
ENTRYPOINT [ "/ha_entrypoint.sh" ]
CMD [ "/usr/bin/env" ]

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

ENV HEALTH_PORT="9980" \
    HEALTH_URL=""
HEALTHCHECK \
    --interval=5s \
    --retries=5 \
    --start-period=30s \
    --timeout=25s \
    CMD curl -A "HealthCheck: Docker/1.0" -s -f "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" &>/dev/null || exit 1
