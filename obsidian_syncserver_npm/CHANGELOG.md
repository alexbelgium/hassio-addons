# Changelog


## 3.5.2.1

- Pin the Nginx Proxy Manager base image to 2.15.1 instead of tracking :latest, so builds are reproducible and the CouchDB runtime copied in from couchdb:3.5.2 keeps a known-compatible Debian trixie ABI

## 3.5.2

- Initial release: couchdb:3.5.2 as an Obsidian Self-hosted LiveSync backend, bundled with Nginx Proxy Manager for TLS and certificate management
- NPM admin UI on port 81; HTTPS on 443; CouchDB also reachable directly on 5984
- Seeds a default nginx host proxying to CouchDB with the settings LiveSync needs: Authorization header passthrough and WebSocket upgrade
- Applies the CouchDB configuration LiveSync requires on every start: single-node cluster, CORS for Obsidian app origins, mandatory authentication, 4 GB max request size, 50 MB max document size
- Creates the vault database automatically
- Generates and persists a strong admin password when none is set
- Stores data under /config/obsidian-syncserver/data so it survives reinstalls and is included in Home Assistant backups
- Symlinks /etc/letsencrypt to /data so NPM certificates persist across restarts
