# Changelog


## 3.5.2

- Initial release wrapping couchdb:3.5.2 as an Obsidian Self-hosted LiveSync backend
- Applies the CouchDB configuration LiveSync requires on every start: single-node cluster, CORS for Obsidian app origins, mandatory authentication, 4 GB max request size, 50 MB max document size
- Creates the vault database automatically
- Generates and persists a strong admin password when none is set
- Stores data under /config/obsidian-syncserver/data so it survives reinstalls and is included in Home Assistant backups
- Plain HTTP on port 5984; use a reverse proxy for TLS if you need mobile sync
