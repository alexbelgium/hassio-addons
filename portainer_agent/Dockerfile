# Portainer Agent with bashio main + simplified protection mode check
# Fix for: FATAL: PROTECTION MODE IS ENABLED! error when protection mode is OFF
# Approach: Level 1 (standard bashio) + Level 2 (socket fallback)

ARG BUILD_FROM
ARG BUILD_ARCH
FROM $BUILD_FROM

# Step 1: Replace bashio v0.17.5 with main branch for improved API error handling
RUN rm -rf /usr/lib/bashio /usr/bin/bashio && \
    curl -f -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/main.tar.gz" && \
    test -f /tmp/bashio.tar.gz && test -s /tmp/bashio.tar.gz || \
        (echo "ERROR: bashio download failed or file is empty" && exit 1) && \
    mkdir /tmp/bashio && \
    tar -xzf /tmp/bashio.tar.gz --strip 1 -C /tmp/bashio || \
        (echo "ERROR: bashio tar extraction failed" && exit 1) && \
    test -d /tmp/bashio/lib || \
        (echo "ERROR: bashio lib directory not found after extraction" && exit 1) && \
    mv /tmp/bashio/lib /usr/lib/bashio && \
    ln -s /usr/lib/bashio/bashio /usr/bin/bashio && \
    rm -rf /tmp/bashio /tmp/bashio.tar.gz

# Step 2: Get agent from official image
COPY --from=ghcr.io/portainerci/agent:latest /app /app

# Step 3: Add tzdata and timezone support
RUN apk add --no-cache tzdata
ADD https://github.com/golang/go/raw/master/lib/time/zoneinfo.zip /zoneinfo.zip
ENV ZONEINFO /zoneinfo.zip

# Step 4: Set S6 init system wait times
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

# Step 5: Copy rootfs from official image
COPY --from=ghcr.io/portainerci/agent:latest / /

# Step 6: Override the run script with simplified protection mode check
RUN mkdir -p /etc/services.d/portainer_agent

RUN cat > /etc/services.d/portainer_agent/run <<'EOF'
#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e
# Home Assistant Community Add-on: portainer_agent
# PATCHED: Simplified protection mode check with socket fallback

bashio::require.unprotected.fixed() {
    local protected

    bashio::log.info "Checking protection mode..."

    # Level 1: Try standard bashio method
    protected=$(bashio::addon.protected 'self' 2>/dev/null || echo "unknown")

    if [[ "${protected}" != "unknown" ]]; then
        # API call succeeded - use result
        bashio::log.debug "Protection mode: ${protected}"
        if [[ "${protected}" == "false" ]] || [[ -z "${protected}" ]]; then
            return 0
        fi
    else
        # Level 2: Fallback - Check Docker socket directly
        # Logic: If protection mode is OFF, Docker socket WILL be accessible
        bashio::log.warning "Could not determine protection mode via API, checking Docker socket..."

        if [ -S /run/docker.sock ]; then
            bashio::log.info "Docker socket is accessible - protection mode is OFF"
            return 0
        else
            bashio::log.fatal "Docker socket not accessible!"
            return 1
        fi
    fi

    # If we get here, protection mode is ON
    bashio::log.fatal "PROTECTION MODE IS ENABLED!"
    bashio::log.fatal ""
    bashio::log.fatal "To be able to use this add-on, you'll need to disable"
    bashio::log.fatal "protection mode on this add-on. Without it, the add-on"
    bashio::log.fatal "is unable to access Docker."
    bashio::log.fatal ""
    bashio::log.fatal "Steps:"
    bashio::log.fatal " - Go to the Supervisor Panel."
    bashio::log.fatal " - Click on this add-on."
    bashio::log.fatal " - Set the 'Protection mode' switch to off."
    bashio::log.fatal " - Restart the add-on."
    bashio::log.fatal ""
    bashio::log.fatal "Access to Docker allows you to do really powerful things"
    bashio::log.fatal "including complete destruction of your system."
    bashio::log.fatal "Please, be sure you know what you are doing before"
    bashio::log.fatal "enabling this feature (and this add-on)!"
    return 1
}

# Call our fixed function
bashio::require.unprotected.fixed

bashio::log.info "Starting Portainer Agent"

# Launch app
cd /app || true
if bashio::config.has_value 'PORTAINER_AGENT_ARGS'; then
    ./agent "$PORTAINER_AGENT_ARGS"
else
    ./agent
fi
EOF

RUN chmod +x /etc/services.d/portainer_agent/run

ENTRYPOINT ["/init"]

HEALTHCHECK --interval=5s --start-period=30s --timeout=5s --retries=3 \
  CMD /usr/sbin/healthcheck || exit 1
