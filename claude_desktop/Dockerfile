#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#=== Home Assistant Addon ===#

#################
# 1 Build Image #
#################

ARG BUILD_FROM
ARG BUILD_VERSION

# virtiofsd is only packaged for Debian trixie/sid, not Bookworm or bookworm-backports;
# installing the trixie .deb on the Bookworm runtime would pull a binary linked against a
# newer GLIBC. Build the current crates.io release from source on Bookworm so the daemon's
# ABI matches the add-on runtime. It has no prebuilt binaries, hence the source build.
# Cowork shares the workspace into its qemu microVM through virtiofsd.
FROM rust:1.91-bookworm AS virtiofsd-builder
# BUILD_DATE busts the cache so each image build compiles the current crates.io release
ARG BUILD_DATE=unknown
RUN echo "Build date marker: ${BUILD_DATE}" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libseccomp-dev \
        libcap-ng-dev \
        pkg-config \
        clang \
        libclang-dev && \
    cargo install virtiofsd --locked --root /out && \
    /out/bin/virtiofsd --version && \
    rm -rf /var/lib/apt/lists/*

FROM ${BUILD_FROM}
ARG BUILD_ARCH
ARG TARGETARCH

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
    if [ -d /etc/services.d ] && ls /etc/services.d/*/run 1> /dev/null 2>&1; then sed -i "1a set +e" /etc/services.d/*/run; fi

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

# Add rootfs. Only the directories this add-on ships scripts in are traversed, so the chmod
# cannot alter executables elsewhere in the image.
COPY rootfs/ /
RUN find /etc/cont-init.d /etc/s6-overlay /defaults /usr/local/bin -type f \
        \( -name "*.sh" -o -name "run" -o -name "finish" -o -name "ha-cli" -o -name "codex-login" -o -name "codex-mcp" \) -print -exec chmod +x {} \; && \
    chmod +x /usr/local/bin/claude

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Install Claude Desktop, Claude Code, Python tooling, and lightweight local validators.
# gnome-keyring is intentionally NOT installed: it prompts for a keyring password on first
# boot, which blocks Claude Desktop from launching. Sign-in persistence instead uses Electron's
# built-in --password-store=basic (rootfs/defaults/autostart) — no daemon, no prompt — together
# with rootfs/etc/cont-init.d/86-claude_safestorage.sh, which patches app.asar to opt into that
# backend. Electron ignores --password-store=basic without the app-side opt-in, so both are
# required for the sign-in to survive a restart.
# The cowork virtualization stack (qemu-system-x86 + ovmf firmware) lets Claude Code launch
# its sandbox microVM; libseccomp2 and libcap-ng0 are the shared libraries the source-built
# virtiofsd daemon links against at runtime. Docker itself is NOT installed here: this base
# image already ships Docker-in-Docker (docker-ce + containerd.io from Docker's own apt repo,
# started via the pre-existing START_DOCKER env var) — installing Debian's docker.io package
# on top pulls in Debian's own containerd/runc, which apt refuses because they Conflict with
# the base image's already-installed containerd.io.
# gh comes from GitHub's own apt repo: Debian Bookworm's gh is frozen at 2.23, which predates
# multi-account `gh auth switch`. 81-claude_update.sh upgrades these vendor-repo packages at boot.
RUN install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc https://downloads.claude.ai/claude-desktop/key.asc && \
    curl -fsSLo /etc/apt/keyrings/claude-code.asc https://downloads.claude.ai/keys/claude-code.asc && \
    curl -fsSLo /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" > /etc/apt/sources.list.d/claude-desktop.list && \
    echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" > /etc/apt/sources.list.d/claude-code.list && \
    echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
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
        jq \
        shellcheck \
        yamllint \
        qemu-system-x86 \
        ovmf \
        libseccomp2 \
        libcap-ng0 && \
    test -x /usr/bin/claude && \
    gh --version && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# No bespoke GPU driver install. The LSIO base image already provides the userspace stack that
# hardware rendering actually uses, and it does so at a newer version than adding it here would:
# libgl1-mesa-dri and mesa-vulkan-drivers come from bookworm-backports Mesa 25.0.7, where a
# plain `apt-get install` of the same names is at best a no-op.
#
# There used to be an amd64 block here installing intel-media-va-driver-non-free, libgl1-mesa-dri,
# mesa-vulkan-drivers and vainfo. It never ran in any release: it was guarded by
# `if [[ ... ]]`, and with no SHELL directive RUN executes under /bin/sh — dash, which has no
# `[[`. dash printed `[[: not found`, the condition was false, and the RUN still exited 0, so
# every build silently skipped it and still passed. (An earlier fix corrected the gate variable
# from TARGETARCH to BUILD_ARCH but left the `[[`, so it stayed dead.) Confirmed in the shipped
# 2026.08.03 amd64 image: no vainfo, no intel-media-va-driver-non-free, no matching apt history.
#
# It was removed rather than repaired, because measurement showed it had nothing to add:
#   - Hardware OpenGL already works without it. In the shipped image the Chromium GPU process
#     loads the Mesa gallium megadriver over DRI3 and holds 8 fds on /dev/dri/renderD128, with
#     no swrast/llvmpipe in the GL path.
#   - The only genuinely new payload, intel-media-va-driver-non-free, does not fix anything
#     here. Installed live alongside vainfo on the running add-on, VA-API failed identically to
#     the free driver — `iHD_drv_video.so init failed` on both /dev/dri/renderD128 and card0,
#     with both 23.1.1 builds. The failure is below the add-on, in the host i915/GuC stack.
# Repairing the guard would therefore have turned dead code into an untested apt transaction
# that swaps a base-image package for no measured benefit.

# virtiofsd is built from source in its own stage; executing it here makes an ABI mismatch
# fail the image build instead of surfacing at runtime.
COPY --from=virtiofsd-builder /out/bin/virtiofsd /usr/bin/virtiofsd
RUN /usr/bin/virtiofsd --version

# Fix Selkies startup when PulseAudio module initialization fails
# hadolint ignore=DL3059
RUN if [ -f /etc/s6-overlay/s6-rc.d/svc-selkies/run ]; then \
        sed -i "1a\set +e" /etc/s6-overlay/s6-rc.d/svc-selkies/run; \
    fi

# Modules
ARG MODULES="00-banner.sh 00-global_var.sh 01-custom_script.sh 00-local_mounts.sh 00-smb_mounts.sh 90-dns_set.sh"

# BUILD_DATE changes on every CI run, busting this layer's cache. The builder reuses
# the layers of the previous image, so without it a rebuild keeps the .templates/
# scripts and the "latest" tool downloads below from the first build and never picks up
# later changes. Layers that must track latest releases are placed after it.
ARG BUILD_DATE=unknown

# Install the latest upstream hadolint, actionlint, rtk and tokensave releases for both
# supported architectures. The release tag is the redirect target of /releases/latest (no
# GitHub API, so no token is needed in CI), resolved once per tool and reused for the binary
# and its checksum file; every download is verified with sha256sum and the build fails on a
# mismatch or a missing checksum line. rtk ships static musl builds; the tokensave prebuilt
# needs GLIBC 2.34, which this base image exceeds. Placed after BUILD_DATE so each CI build
# re-resolves "latest" instead of reusing a cached layer.
# hadolint ignore=DL3003,DL3059,DL4006
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) hadolint_arch="x86_64"; actionlint_arch="amd64"; rtk_arch="x86_64"; tokensave_arch="x86_64" ;; \
        arm64) hadolint_arch="arm64"; actionlint_arch="arm64"; rtk_arch="aarch64"; tokensave_arch="aarch64" ;; \
        *) echo "Unsupported validation-tools architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    tmp="$(mktemp -d)"; \
    latest_tag() { curl -fsSLI --retry 3 --retry-delay 2 -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's#.*/##'; }; \
    fetch() { curl -fsSL --retry 3 --retry-delay 2 -o "${tmp}/$(basename "$1")" "$1"; }; \
    verify() { line="$(awk -v a="$2" '{n=$2; sub(/^\*/, "", n); if (n == a) print}' "${tmp}/$1")"; test -n "${line}"; (cd "${tmp}" && echo "${line}" | sha256sum -c -); }; \
    hadolint_tag="$(latest_tag hadolint/hadolint)"; test -n "${hadolint_tag}" && test "${hadolint_tag}" != "latest"; \
    base="https://github.com/hadolint/hadolint/releases/download/${hadolint_tag}"; \
    asset="hadolint-linux-${hadolint_arch}"; \
    fetch "${base}/${asset}"; fetch "${base}/checksums.sha256"; \
    verify checksums.sha256 "${asset}"; \
    install -m 0755 "${tmp}/${asset}" "/usr/local/bin/hadolint"; \
    actionlint_tag="$(latest_tag rhysd/actionlint)"; test -n "${actionlint_tag}" && test "${actionlint_tag}" != "latest"; \
    base="https://github.com/rhysd/actionlint/releases/download/${actionlint_tag}"; \
    asset="actionlint_${actionlint_tag#v}_linux_${actionlint_arch}.tar.gz"; \
    fetch "${base}/${asset}"; fetch "${base}/actionlint_${actionlint_tag#v}_checksums.txt"; \
    verify "actionlint_${actionlint_tag#v}_checksums.txt" "${asset}"; \
    mkdir "${tmp}/actionlint"; tar -xzf "${tmp}/${asset}" -C "${tmp}/actionlint" actionlint; \
    install -m 0755 "${tmp}/actionlint/actionlint" "/usr/local/bin/actionlint"; \
    rtk_tag="$(latest_tag rtk-ai/rtk)"; test -n "${rtk_tag}" && test "${rtk_tag}" != "latest"; \
    base="https://github.com/rtk-ai/rtk/releases/download/${rtk_tag}"; \
    asset="rtk-${rtk_arch}-unknown-linux-musl.tar.gz"; \
    fetch "${base}/${asset}"; fetch "${base}/checksums.txt"; \
    verify checksums.txt "${asset}"; \
    mkdir "${tmp}/rtk"; tar -xzf "${tmp}/${asset}" -C "${tmp}/rtk"; \
    install -m 0755 "$(find "${tmp}/rtk" -type f -name rtk | head -n 1)" "/usr/local/bin/rtk"; \
    tokensave_tag="$(latest_tag aovestdipaperino/tokensave)"; test -n "${tokensave_tag}" && test "${tokensave_tag}" != "latest"; \
    base="https://github.com/aovestdipaperino/tokensave/releases/download/${tokensave_tag}"; \
    asset="tokensave-${tokensave_tag}-${tokensave_arch}-linux.tar.gz"; \
    fetch "${base}/${asset}"; fetch "${base}/SHA256SUMS"; \
    verify SHA256SUMS "${asset}"; \
    mkdir "${tmp}/tokensave"; tar -xzf "${tmp}/${asset}" -C "${tmp}/tokensave"; \
    install -m 0755 "$(find "${tmp}/tokensave" -type f -name tokensave | head -n 1)" "/usr/local/bin/tokensave"; \
    rm -rf "${tmp}"; \
    hadolint --version; actionlint -version; rtk --version; tokensave --version

# Install only the Headroom proxy, code-compression, and MCP features used by this add-on,
# plus mcp-proxy (stdio->HTTP bridge for the Home Assistant MCP server) and uv (fast
# installer used for the additional_pip option). The `proxy` extra already ships the ONNX
# runtime + transformers needed by the Kompress compressor — the `ml` extra (full PyTorch,
# ~5 GB with CUDA wheels) is deliberately NOT installed; svc-headroom pre-warms the ONNX
# model into the persistent HF cache instead. Upgraded to the latest releases on every image build.
# hadolint ignore=DL3013,DL3042,DL3059
RUN apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    pip3 install --break-system-packages --upgrade "headroom-ai[proxy,code,mcp]" mcp-proxy uv websockets && \
    headroom --version && \
    mcp-proxy --help >/dev/null && \
    uv --version && \
    python3 -c 'import websockets' && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /root/.cache

# Automatic modules download
RUN echo "Build date marker: ${BUILD_DATE}" && \
    curl -fsSL --retry 3 --retry-delay 2 \
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
