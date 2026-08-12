# Changelog


## 3.5.2

- Initial release wrapping couchdb:3.5.2 as an Obsidian Self-hosted LiveSync backend with native HTTPS
- Serves HTTPS on port 6984 using certificates supplied in /ssl, so mobile Obsidian can sync
- Validates the certificate before starting: presence, PEM parsing, expiry, and certificate/key match, each reported with its specific cause
- Logs the certificate's covered hostnames and expiry date
- Applies the CouchDB configuration LiveSync requires on every start: single-node cluster, CORS for Obsidian app origins, mandatory authentication, 4 GB max request size, 50 MB max document size
- Creates the vault database automatically
- Generates and persists a strong admin password when none is set
- Stores data under /config/obsidian-syncserver/data so it survives reinstalls and is included in Home Assistant backups
