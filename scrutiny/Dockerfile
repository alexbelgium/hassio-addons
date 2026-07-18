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
FROM ${BUILD_FROM}

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0 \
    S6_STAGE2_HOOK="/ha_entrypoint.sh" \
    SCRUTINY_HA_ADDON_SLUG="scrutiny"

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /
RUN find . -type f \( -name "*.sh" -o -name "run" -o -name "finish" \) -print -exec chmod +x {} \; && \
    chmod 0755 /usr/local/bin/scrutiny-ha-influxdb-preflight && \
    if [ -d /command ]; then ln -sf /command/* /usr/bin/; fi

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES="00-banner.sh 01-custom_script.sh"

# Automatic modules download
COPY ha_automodules.sh /ha_automodules.sh
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="jq \
    curl \
    cifs-utils \
    gzip \
    nginx"

# Automatic apps & bashio
COPY ha_autoapps.sh /ha_autoapps.sh
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Keep the repository initialization hook, but return after it has prepared the
# cont-init scripts. Upstream s6 remains responsible for supervising services.
COPY ha_entrypoint.sh /ha_entrypoint.sh
RUN chmod 0755 /ha_entrypoint.sh && \
    awk '!inserted && $0 == "if $PID1; then" { \
        print "if ! $PID1; then"; \
        print "  echo \"Initialization hook complete\""; \
        print "  exit 0"; \
        print "fi"; \
        inserted=1 \
    } { print }' /ha_entrypoint.sh > /ha_entrypoint.sh.tmp && \
    mv /ha_entrypoint.sh.tmp /ha_entrypoint.sh && \
    chmod 0755 /ha_entrypoint.sh

# Install bashio
COPY bashio-standalone.sh /usr/local/lib/bashio-standalone.sh
RUN chmod 0755 /usr/local/lib/bashio-standalone.sh

# Build-time migration tests cover path and content equality, symbolic links,
# atomic replacement, marker checksums, idempotency, and fail-closed states.
RUN test -x /init && \
    test -x /ha_entrypoint.sh && \
    bash -n /ha_entrypoint.sh && \
    grep -q 'Initialization hook complete' /ha_entrypoint.sh && \
    bash -n /usr/local/bin/scrutiny-ha-influxdb-preflight && \
    test_root="$(mktemp -d)" && \
    mkdir -p "$test_root/data/influxdb/engine/nested" "$test_root/share" "$test_root/stale/influxdb/engine/nested" && \
    printf 'bolt-test\n' > "$test_root/data/influxdb/influxd.bolt" && \
    printf 'shard-one\n' > "$test_root/data/influxdb/engine/shard-one" && \
    printf 'shard-two\n' > "$test_root/data/influxdb/engine/nested/shard-two" && \
    ln -s nested/shard-two "$test_root/data/influxdb/engine/current-link" && \
    printf 'stale-bolt\n' > "$test_root/stale/influxdb/influxd.bolt" && \
    printf 'stale-one\n' > "$test_root/stale/influxdb/engine/shard-one" && \
    printf 'shard-two\n' > "$test_root/stale/influxdb/engine/nested/shard-two" && \
    ln -s shard-one "$test_root/stale/influxdb/engine/current-link" && \
    tar -C "$test_root/stale" -czf "$test_root/share/influxdb-pre-2.9.tar.gz" influxdb && \
    stale_sha="$(sha256sum "$test_root/share/influxdb-pre-2.9.tar.gz" | awk '{print $1}')" && \
    SCRUTINY_INFLUXDB_DATA_DIR="$test_root/data/influxdb" \
    SCRUTINY_INFLUXDB_BACKUP_DIR="$test_root/share" \
        /usr/local/bin/scrutiny-ha-influxdb-preflight && \
    backup_sha="$(sha256sum "$test_root/share/influxdb-pre-2.9.tar.gz" | awk '{print $1}')" && \
    test "$stale_sha" != "$backup_sha" && \
    test "$(tar -xOzf "$test_root/share/influxdb-pre-2.9.tar.gz" influxdb/engine/shard-one)" = "shard-one" && \
    tar -tvzf "$test_root/share/influxdb-pre-2.9.tar.gz" influxdb/engine/current-link | grep -q ' -> nested/shard-two$' && \
    grep -q '^state=legacy-backup$' "$test_root/data/influxdb/.scrutiny-influxdb-2.9-preflight-complete" && \
    grep -q '^validation=content-sha256-v1$' "$test_root/data/influxdb/.scrutiny-influxdb-2.9-preflight-complete" && \
    grep -q "^backup_sha256=${backup_sha}$" "$test_root/data/influxdb/.scrutiny-influxdb-2.9-preflight-complete" && \
    SCRUTINY_INFLUXDB_DATA_DIR="$test_root/data/influxdb" \
    SCRUTINY_INFLUXDB_BACKUP_DIR="$test_root/share" \
        /usr/local/bin/scrutiny-ha-influxdb-preflight && \
    test "$backup_sha" = "$(sha256sum "$test_root/share/influxdb-pre-2.9.tar.gz" | awk '{print $1}')" && \
    printf 'corrupt\n' > "$test_root/share/influxdb-pre-2.9.tar.gz" && \
    if SCRUTINY_INFLUXDB_DATA_DIR="$test_root/data/influxdb" \
        SCRUTINY_INFLUXDB_BACKUP_DIR="$test_root/share" \
        /usr/local/bin/scrutiny-ha-influxdb-preflight; then exit 1; fi && \
    failure_root="$(mktemp -d)" && \
    mkdir -p "$failure_root/data/influxdb/engine" "$failure_root/share" "$failure_root/old/influxdb/engine" && \
    mkfifo "$failure_root/data/influxdb/engine/unsupported-fifo" && \
    printf 'preserve-me\n' > "$failure_root/old/influxdb/engine/old-file" && \
    tar -C "$failure_root/old" -czf "$failure_root/share/influxdb-pre-2.9.tar.gz" influxdb && \
    preserved_sha="$(sha256sum "$failure_root/share/influxdb-pre-2.9.tar.gz" | awk '{print $1}')" && \
    if SCRUTINY_INFLUXDB_DATA_DIR="$failure_root/data/influxdb" \
        SCRUTINY_INFLUXDB_BACKUP_DIR="$failure_root/share" \
        /usr/local/bin/scrutiny-ha-influxdb-preflight; then exit 1; fi && \
    test "$preserved_sha" = "$(sha256sum "$failure_root/share/influxdb-pre-2.9.tar.gz" | awk '{print $1}')" && \
    empty_root="$(mktemp -d)" && \
    mkdir -p "$empty_root/data/influxdb" "$empty_root/share" && \
    SCRUTINY_INFLUXDB_DATA_DIR="$empty_root/data/influxdb" \
    SCRUTINY_INFLUXDB_BACKUP_DIR="$empty_root/share" \
        /usr/local/bin/scrutiny-ha-influxdb-preflight && \
    grep -q '^state=no-legacy-data$' "$empty_root/data/influxdb/.scrutiny-influxdb-2.9-preflight-complete" && \
    grep -q '^validation=no-data-v1$' "$empty_root/data/influxdb/.scrutiny-influxdb-2.9-preflight-complete" && \
    test ! -e "$empty_root/share/influxdb-pre-2.9.tar.gz" && \
    rm -rf "$test_root" "$failure_root" "$empty_root"

# Scrutiny's image already includes s6-overlay and defines all services under
# /etc/services.d. Keep /init as PID 1 so service readiness and s6-svc calls work.
ENTRYPOINT [ "/init" ]

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

ENV HEALTH_PORT="8080" \
    HEALTH_URL="/api/health"
HEALTHCHECK \
    --interval=5s \
    --retries=5 \
    --start-period=30s \
    --timeout=25s \
    CMD curl -A "HealthCheck: Docker/1.0" -s -f "http://127.0.0.1:${HEALTH_PORT}${HEALTH_URL}" &>/dev/null || exit 1
