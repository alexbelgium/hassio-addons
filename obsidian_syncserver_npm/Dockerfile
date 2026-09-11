# Global build args must be declared before the first FROM to be usable there.
ARG BUILD_FROM=jc21/nginx-proxy-manager:2.15.1
ARG COUCHDB_FROM=couchdb:3.5.2

# Stage 1: source of the CouchDB runtime. CouchDB ships a self-contained
# release under /opt/couchdb, including its own Erlang runtime (erts-*), so
# it can be lifted into another image without installing Erlang separately.
FROM ${COUCHDB_FROM} AS couchdb

# Stage 2: Nginx Proxy Manager, which supplies s6-overlay and the admin UI.
# Both images are Debian trixie, so the CouchDB release is binary compatible.
FROM ${BUILD_FROM}

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        openssl \
        ripgrep \
        libicu76 \
        libmozjs-128-0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=couchdb /opt/couchdb /opt/couchdb
COPY --from=couchdb /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh

# CouchDB refuses to run as root and expects to own its runtime directories.
RUN groupadd -g 5984 couchdb \
    && useradd -u 5984 -g couchdb -d /opt/couchdb -s /bin/bash couchdb \
    && chown -R couchdb:couchdb /opt/couchdb \
    && chmod +x /docker-entrypoint.sh

COPY run.sh /run.sh
COPY rootfs /
RUN chmod +x /run.sh \
    && chmod +x /etc/s6-overlay/s6-rc.d/couchdb/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/couchdb/finish \
    && chmod +x /etc/s6-overlay/s6-rc.d/addon-init/script

ARG BUILD_VERSION
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="aarch64|amd64"

ENTRYPOINT ["/init"]
