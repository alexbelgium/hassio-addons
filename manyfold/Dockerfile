ARG BUILD_FROM=ghcr.io/manyfold3d/manyfold-solo:latest
FROM ${BUILD_FROM}

# hadolint ignore=DL3041
RUN set -eux; \
    if command -v apk >/dev/null 2>&1; then \
      apk add --no-cache bash coreutils jq openssl; \
    elif command -v apt-get >/dev/null 2>&1; then \
      apt-get update; \
      apt-get install -y --no-install-recommends bash coreutils jq openssl ca-certificates; \
      rm -rf /var/lib/apt/lists/*; \
    elif command -v dnf >/dev/null 2>&1; then \
      dnf install -y bash coreutils jq openssl; \
      dnf clean all; \
    else \
      echo "Unsupported base image: missing apk/apt-get/dnf"; \
      exit 1; \
    fi

COPY run.sh /run.sh
COPY rootfs /

RUN chmod +x /run.sh \
    && chmod +x /etc/s6-overlay/s6-rc.d/manyfold/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/manyfold/finish

ENTRYPOINT ["/init"]
