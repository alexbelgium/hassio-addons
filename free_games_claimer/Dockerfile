#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#=== Home Assistant Add-on ===#

ARG BUILD_FROM="debian:bookworm-slim"
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND="noninteractive"
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
ARG UPSTREAM_REPOSITORY="P-Adamiec/Free-Games-Claimer-Remaster"
ARG UPSTREAM_REF="cca4992354215cef8807b748575af797606627f4"

ENV S6_CMD_WAIT_FOR_SERVICES="1" \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
    S6_SERVICES_GRACETIME="0" \
    VNC_PORT="5900" \
    NOVNC_PORT="6080" \
    WIDTH="1280" \
    HEIGHT="720" \
    DEPTH="24" \
    SHOW="1" \
    COMMIT="${UPSTREAM_REF}" \
    BRANCH="main" \
    NOW="${BUILD_DATE}"

# Install the dependencies used by Free Games Claimer Remaster. The upstream
# Dockerfile supports both amd64 (Google Chrome) and arm64 (Chromium), so the
# add-on keeps its existing multi-architecture support.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dos2unix \
        gnupg \
        gzip \
        jq \
        python3 \
        python3-pip \
        tar \
        tini \
    && mkdir -p /etc/apt/keyrings \
    && curl --proto "=https" --tlsv1.2 -fsSL https://packagecloud.io/dcommander/virtualgl/gpgkey \
        | gpg --dearmor -o /etc/apt/trusted.gpg.d/VirtualGL.gpg \
    && curl --proto "=https" --tlsv1.2 -fsSL https://packagecloud.io/dcommander/turbovnc/gpgkey \
        | gpg --dearmor -o /etc/apt/trusted.gpg.d/TurboVNC.gpg \
    && curl --proto "=https" --tlsv1.2 -fsSL https://raw.githubusercontent.com/VirtualGL/repo/main/VirtualGL.list \
        > /etc/apt/sources.list.d/VirtualGL.list \
    && curl --proto "=https" --tlsv1.2 -fsSL https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list \
        > /etc/apt/sources.list.d/TurboVNC.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        novnc \
        ratpoison \
        turbovnc \
        virtualgl \
        websockify \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libatspi2.0-0 \
        libcairo2 \
        libcups2 \
        libgbm1 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxkbcommon0 \
    && if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
            | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg; \
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
            > /etc/apt/sources.list.d/google-chrome.list; \
        apt-get update; \
        apt-get install -y --no-install-recommends google-chrome-stable; \
    else \
        apt-get install -y --no-install-recommends chromium; \
    fi \
    && ln -sf /usr/share/novnc/vnc_auto.html /usr/share/novnc/index.html \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && apt-get purge -y gnupg \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/* /var/tmp/* /tmp/* /usr/share/doc/*

# Install a deterministic snapshot of the replacement upstream. Updating the
# upstream reference is intentionally explicit so image contents cannot change
# without an add-on version bump.
WORKDIR /fgc
RUN curl --proto "=https" --tlsv1.2 -fsSL \
        "https://github.com/${UPSTREAM_REPOSITORY}/archive/${UPSTREAM_REF}.tar.gz" \
        -o /tmp/free-games-claimer-remaster.tar.gz \
    && tar -xzf /tmp/free-games-claimer-remaster.tar.gz --strip-components=1 -C /fgc \
    && python3 -m pip install --no-cache-dir --break-system-packages -r requirements.txt \
    && dos2unix ./*.sh \
    && chmod +x ./*.sh \
    && cp docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh \
    && chmod 0755 /usr/local/bin/docker-entrypoint.sh \
    && rm -f /tmp/free-games-claimer-remaster.tar.gz \
    && rm -rf /fgc/data \
    && ln -s /data /fgc/data

# Add Home Assistant integration files and shared helper modules.
COPY rootfs/ /
RUN find /etc/cont-init.d /usr/local/bin -type f -name "*.sh" -exec chmod 0755 {} + \
    && chmod 0755 /usr/local/bin/migrate_vogler_data.py

ARG MODULES="00-banner.sh 01-custom_script.sh"
COPY ha_automodules.sh /ha_automodules.sh
RUN chmod 0755 /ha_automodules.sh \
    && /ha_automodules.sh "${MODULES}" \
    && rm /ha_automodules.sh

ENV PACKAGES=""
COPY ha_autoapps.sh /ha_autoapps.sh
RUN chmod 0755 /ha_autoapps.sh \
    && /ha_autoapps.sh "${PACKAGES}" \
    && rm /ha_autoapps.sh

ENV S6_STAGE2_HOOK="/ha_entrypoint.sh"
COPY ha_entrypoint.sh /ha_entrypoint.sh
COPY bashio-standalone.sh /usr/local/lib/bashio-standalone.sh
RUN chmod 0755 /ha_entrypoint.sh /usr/local/lib/bashio-standalone.sh

EXPOSE 5900 6080
ENTRYPOINT ["/usr/bin/env"]
CMD ["/ha_entrypoint.sh"]

LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.licenses="AGPL-3.0" \
    org.opencontainers.image.url="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/master/free_games_claimer/README.md" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${BUILD_REF}" \
    org.opencontainers.image.version="${BUILD_VERSION}" \
    io.hass.upstream="https://github.com/${UPSTREAM_REPOSITORY}/tree/${UPSTREAM_REF}"
