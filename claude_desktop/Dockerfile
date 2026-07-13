#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#=== Home Assistant Addon ===#

#################
# 1 Build Image #
#################

ARG BUILD_FROM
ARG BUILD_VERSION
ARG RTK_VERSION="v0.43.0"
ARG RTK_COMMIT="5a7880d404db8364d602f2ecdc41dd790f64013f"

# The upstream aarch64 release is cross-built on ubuntu-latest and requires
# GLIBC 2.39. Build the pinned source on Bookworm instead so it is compatible
# with the add-on runtime on both supported architectures.
FROM rust:1.91-bookworm AS rtk-builder
ARG RTK_VERSION
ARG RTK_COMMIT
RUN git clone --depth 1 --branch "${RTK_VERSION}" https://github.com/rtk-ai/rtk.git /src/rtk && \
    test "$(git -C /src/rtk rev-parse HEAD)" = "${RTK_COMMIT}" && \
    cd /src/rtk && \
    cargo build --release --locked && \
    install -D -m 0755 target/release/rtk /out/rtk && \
    /out/rtk --version

FROM ${BUILD_FROM}

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

USER root

# load volume
VOLUME [ "/sys/fs/cgroup" ]

# Allow UID and GID setting
# hadolint ignore=SC2015,DL4006,SC2013,SC2086
RUN \
    usermod --home /data/data abc && \
    if [[ -d /etc/services.d ]] && ls /etc/services.d/*/run 1> /dev/"ubunturesolute-version-6dc44b0e" 2>&1; then sed -i "1a set +e" /etc/services.d/*/run; fi

ARG TEMPLATE_BASE_URL="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates"

# Global LSIO modifications
ARG CONFIGLOCATION="/data/data"
RUN curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_lsio.sh "${TEMPLATE_BASE_URL}/ha_lsio.sh" && \
    chmod 744 /ha_lsio.sh && \
    if grep -qr "lsio" /etc; then /ha_lsio.sh "$CONFIGLOCATION"; fi && \
    rm /ha_lsio.sh

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /
RUN find . -type f \( -name "*.sh" -o -name "run" -o -name "finish" \) -print -exec chmod +x {} \; && \
    chmod +x /usr/local/bin/claude-direct /usr/local/bin/claude-headroom /usr/local/bin/claude-terminal-shell

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Install Claude Desktop, Claude Code, browser-terminal tooling, and Python tooling
RUN install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc https://downloads.claude.ai/claude-desktop/key.asc && \
    curl -fsSLo /etc/apt/keyrings/claude-code.asc https://downloads.claude.ai/keys/claude-code.asc && \
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" > /etc/apt/sources.list.d/claude-desktop.list && \
    echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" > /etc/apt/sources.list.d/claude-code.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        claude-desktop \
        claude-code \
        python3-pip \
        libsecret-1-0 \
        dbus-x11 \
        git \
        gh \
        ripgrep \
        tmux && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ttyd is not packaged in Debian bookworm. Install the pinned upstream static binary.
ARG TTYD_VERSION="1.7.7"
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
        amd64) ttyd_arch="x86_64" ;; \
        arm64) ttyd_arch="aarch64" ;; \
        *) echo "Unsupported architecture for ttyd: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac; \
    curl -fsSL --retry 3 --retry-delay 2 \
        -o /usr/local/bin/ttyd \
        "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${ttyd_arch}"; \
    chmod 0755 /usr/local/bin/ttyd; \
    /usr/local/bin/ttyd --version

# Copy the pinned Bookworm-built RTK binary and execute it in the final image.
# This makes an ABI mismatch fail the image build instead of surfacing at runtime.
COPY --from=rtk-builder /out/rtk /usr/local/bin/rtk
RUN /usr/local/bin/rtk --version

# Install only the Headroom proxy, code-compression, and MCP features used by this add-on.
RUN apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    pip3 install --break-system-packages "headroom-ai[proxy,code,mcp]" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /root/.cache

# Fix Selkies startup when PulseAudio module initialization fails
RUN if [ -f /etc/s6-overlay/s6-rc.d/svc-selkies/run ]; then \
        sed -i "1a\set +e" /etc/s6-overlay/s6-rc.d/svc-selkies/run; \
    fi

# Modules
ARG MODULES="00-banner.sh 00-global_var.sh 01-custom_script.sh 00-local_mounts.sh 00-smb_mounts.sh 90-dns_set.sh"

# Automatic modules download
RUN curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_automodules.sh "${TEMPLATE_BASE_URL}/ha_automodules.sh" && \
    chmod 744 /ha_automodules.sh && \
    /ha_automodules.sh "$MODULES" && \
    rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="nginx"

# Automatic apps & bashio
RUN curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_autoapps.sh "${TEMPLATE_BASE_URL}/ha_autoapps.sh" && \
    chmod 744 /ha_autoapps.sh && \
    /ha_autoapps.sh "$PACKAGES" && \
    rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Add entrypoint and standalone bashio compatibility
RUN curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_entrypoint.sh "${TEMPLATE_BASE_URL}/ha_entrypoint.sh" && \
    curl -fsSL --retry 3 --retry-delay 2 \
        -o /usr/local/lib/bashio-standalone.sh "${TEMPLATE_BASE_URL}/bashio-standalone.sh" && \
    chmod 0777 /ha_entrypoint.sh && \
    chmod 0755 /usr/local/lib/bashio-standalone.sh

ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "/ha_entrypoint.sh" ]

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

####################
# 6 HealthcheckNOT #
####################
