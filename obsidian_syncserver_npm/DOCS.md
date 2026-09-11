# Obsidian Sync Server NPM

CouchDB set up as a backend for the [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) plugin in Obsidian, with Nginx Proxy Manager bundled in for TLS and certificate handling.

## How it fits together

Both run in one container under s6 supervision. CouchDB listens on 5984 and holds the vault. Nginx Proxy Manager listens on 80, 81 and 443, and proxies HTTPS through to CouchDB.

On first start the add-on seeds a default nginx host, so port 80 reaches CouchDB before you have configured anything. Create a real proxy host in the admin UI and that takes over.

The seeded config includes the two things LiveSync depends on. `proxy_pass_request_headers on` keeps the `Authorization` header intact, which matters because CouchDB authenticates every request. The `Upgrade` and `Connection` headers allow the long-lived connections replication needs.

Build your own proxy host in the UI and you have to switch Websockets Support on for the same reason.

## Ports

| Port | Use |
| :--- | :--- |
| 443 | HTTPS, point Obsidian here |
| 81 | NPM admin UI |
| 80 | HTTP, certificate validation and redirect |
| 5984 | CouchDB directly |

Since this add-on binds 80, 81 and 443, it cannot run alongside the Nginx Proxy Manager + Static Web Server add-on or anything else holding those ports.

## First login

The admin UI on port 81 starts with well-known default credentials: `admin@example.com` and `changeme`. NPM forces a change on first login. Do it before this add-on is reachable by anything you do not control.

## Certificates

NPM keeps certificates in `/etc/letsencrypt`, which this add-on symlinks to `/data/letsencrypt` so they survive restarts and reinstalls.

For a domain that does not resolve publicly, use a DNS Challenge when requesting a Let's Encrypt certificate. HTTP validation needs the domain to reach port 80 from the internet.

## What the add-on configures in CouchDB

A stock CouchDB will not work as a LiveSync backend. On every start this add-on applies the settings the plugin needs, matching what upstream's own provisioning tool does:

| Setting | Value | Why |
| :--- | :--- | :--- |
| `chttpd/require_valid_user` | `true` | No anonymous access |
| `chttpd_auth/require_valid_user` | `true` | No anonymous access to the auth endpoints |
| `httpd/WWW-Authenticate` | `Basic realm="couchdb"` | Prompts for credentials |
| `httpd/enable_cors`, `chttpd/enable_cors` | `true` | Obsidian behaves like a browser client |
| `cors/credentials` | `true` | Lets it send the auth header cross-origin |
| `cors/origins` | `app://obsidian.md,capacitor://localhost,http://localhost` | Desktop and mobile app origins |
| `chttpd/max_http_request_size` | `4294967296` | Large vault batches |
| `couchdb/max_document_size` | `50000000` | Large notes and attachments |

These get re-applied on each start, so editing them by hand in Fauxton will not stick.

## Storage

The vault database lives in `/config/obsidian-syncserver/data` rather than the add-on's `/data` directory, so it survives a reinstall and **gets picked up by Home Assistant backups**. NPM's own database and certificates live in `/data`.

If you did not set a CouchDB password, the generated one is in `/config/obsidian-syncserver/admin_password`.

## Troubleshooting

Check CouchDB directly first. It separates a CouchDB problem from a proxy problem in one command:

```bash
curl -u admin:YOURPASSWORD http://homeassistant.local:5984/obsidian
```

If that works, CouchDB is fine and whatever is failing lives in the proxy layer.

If the add-on will not start, look for `ERROR` in the log. A malformed `database` name or an unwritable `/config` both stop startup with a message saying which.

If sync connects and then stalls, WebSocket upgrade is off. Turn on Websockets Support in the proxy host settings.

If everything returns 401 through the proxy but works on 5984, the proxy host is not passing the `Authorization` header through.

If desktop syncs but mobile does not, the certificate is either untrusted by the phone or issued for a different hostname. Check with:

```bash
openssl s_client -connect your-domain:443 </dev/null | openssl x509 -noout -subject -dates
```

If the add-on will not start because of a port conflict, something else holds 80, 81 or 443. Stop it, or switch to the plain Obsidian Sync Server behind the proxy you already have.

To see the applied CouchDB configuration:

```bash
curl -u admin:YOURPASSWORD http://homeassistant.local:5984/_node/_local/_config/cors
```

## Updates

This add-on tracks two upstream projects, CouchDB and Nginx Proxy Manager, and the repository's updater handles one upstream per add-on. Its version gets bumped by hand rather than by the weekly update workflow.

## Backups

Home Assistant backs up `/config`, which covers the vault database. For a copy you can move elsewhere, use CouchDB replication or export from Fauxton at `http://<host>:5984/_utils`.
