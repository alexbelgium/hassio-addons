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

ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0 \
    HEADROOM_CONTEXT_TOOL=rtk

USER root
VOLUME [ "/sys/fs/cgroup" ]

ARG TEMPLATE_BASE_URL="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates"
ARG TTYD_VERSION="1.7.7"

##################
# 3 Install apps #
##################

COPY rootfs/ /
RUN find /etc/cont-init.d /etc/s6-overlay /usr/local/bin \
        -type f \( -name "*.sh" -o -name "run" -o -name "finish" -o -path "/usr/local/bin/*" \) \
        -print -exec chmod +x {} \;

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gh \
        jq \
        less \
        nano \
        openssh-client \
        python3-pip \
        ripgrep \
        tmux && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install the official Codex static binary for the target architecture.
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
        amd64) codex_arch="x86_64" ;; \
        arm64) codex_arch="aarch64" ;; \
        *) echo "Unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac; \
    archive="/tmp/codex.tar.gz"; \
    curl -fsSL --retry 3 --retry-delay 2 \
        -o "$archive" \
        "https://github.com/openai/codex/releases/latest/download/codex-${codex_arch}-unknown-linux-musl.tar.gz"; \
    tar -xzf "$archive" -C /tmp; \
    install -m 0755 "/tmp/codex-${codex_arch}-unknown-linux-musl" /usr/local/bin/codex; \
    rm -f "$archive" "/tmp/codex-${codex_arch}-unknown-linux-musl"; \
    codex --version

# ttyd provides the Home Assistant ingress terminal.
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
        amd64) ttyd_arch="x86_64" ;; \
        arm64) ttyd_arch="aarch64" ;; \
        *) echo "Unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac; \
    curl -fsSL --retry 3 --retry-delay 2 \
        -o /usr/local/bin/ttyd \
        "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${ttyd_arch}"; \
    chmod 0755 /usr/local/bin/ttyd; \
    ttyd --version

COPY --from=rtk-builder /out/rtk /usr/local/bin/rtk
RUN rtk --version && \
    pip3 install --break-system-packages --no-cache-dir "headroom-ai[proxy,code,mcp]" && \
    headroom --version

ARG MODULES="00-banner.sh 00-global_var.sh 01-custom_script.sh 00-local_mounts.sh 00-smb_mounts.sh 90-dns_set.sh"
RUN curl -fsSL --retry 3 --retry-delay 2 \
        -o /ha_automodules.sh "${TEMPLATE_BASE_URL}/ha_automodules.sh" && \
    chmod 744 /ha_automodules.sh && \
    /ha_automodules.sh "$MODULES" && \
    rm /ha_automodules.sh

################
# 4 Entrypoint #
################

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
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/master/chatgpt_codex/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

#################
# 6 Healthcheck #
#################

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
    CMD curl -fsS http://127.0.0.1:7681/ > /dev/null || exit 1
