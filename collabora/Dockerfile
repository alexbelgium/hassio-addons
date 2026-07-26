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
# build.json pins the architecture explicitly, collabora/code:latest-amd64 and
# collabora/code:latest-arm64, rather than the multi-arch collabora/code:latest.
# The builder never passes --platform: it runs the amd64 build on a native amd64
# runner and the aarch64 build on a native arm runner, so the only thing that
# decides which Collabora binaries end up in the add-on is this tag. With the
# multi-arch tag that happens to resolve correctly, but only for as long as the
# runner architecture keeps matching the target, and a mismatch would silently
# produce an image full of foreign-architecture binaries. The per-arch tags are
# published in lockstep with latest, so nothing is lost by naming them.
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

# Inherited from the base, declared here so it is visible to hadolint and to
# anyone adding a pipe below. Note that the linkage check does NOT pipe into
# grep: with pipefail an ldd that exits non-zero (a binary it cannot handle at
# all) would make the pipeline fail even though grep matched, and "if" would
# then read that as "no unresolved libraries" -- the one case worth catching.
# Capturing the output and matching it with case avoids the question entirely.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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

# Restore the file capabilities. The official image carries them as extended
# attributes on two binaries:
#   coolforkit-caps  cap_chown,cap_fowner,cap_sys_chroot=ep
#   coolmount        cap_sys_admin=ep
# COPY --from does not transfer extended attributes, so both arrive stripped.
# Nothing about the build notices: coolwsd starts and serves the admin console,
# but every document fails to open because it cannot chroot a kit process. Set
# them again and check they stuck, so a builder without xattr support fails here
# instead of shipping an add-on that only looks like it works.
#
# cap_sys_admin on coolmount only takes effect if the container is given
# SYS_ADMIN, which the add-on does not request; without it Collabora copies its
# child roots instead of bind-mounting them, which is slower but works.
RUN \
    setcap "cap_chown,cap_fowner,cap_sys_chroot=ep" /usr/bin/coolforkit-caps && \
    setcap "cap_sys_admin=ep" /usr/bin/coolmount && \
    caps="$(getcap /usr/bin/coolforkit-caps /usr/bin/coolmount)" && \
    case "$caps" in \
    *cap_sys_chroot*) ;; \
    *) echo "coolforkit-caps lost its capabilities: ${caps}"; exit 1 ;; \
    esac && \
    case "$caps" in \
    *cap_sys_admin*) ;; \
    *) echo "coolmount lost its capabilities: ${caps}"; exit 1 ;; \
    esac

# Fail the build rather than ship an image that cannot start: ha_autoapps.sh is
# invoked with "|| true", and the payload was linked against the libraries of
# the distroless image, so both are worth proving here.
#
# coolwsd itself cannot be executed as a smoke test. It refuses to run as root
# ("Do not run as root. Please run as cool user.", exit 78), and --version does
# not exit either -- the official entrypoint passes it to the long-running
# server to get the version into the log. Checking that every binary resolves
# its libraries proves the same thing and terminates.
RUN \
    command -v openssl > /dev/null && \
    command -v su > /dev/null && \
    for binary in \
    /usr/bin/coolwsd \
    /usr/bin/coolforkit-caps \
    /usr/bin/coolforkit-ns \
    /usr/bin/coolmount \
    /opt/collaboraoffice/program/soffice.bin \
    /opt/collaboraoffice/program/libmergedlo.so; do \
    libs="$(ldd "$binary" 2>&1)"; \
    case "$libs" in \
    *"not found"*) echo "Unresolved libraries in ${binary}:"; echo "$libs"; exit 1 ;; \
    esac; \
    done

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
