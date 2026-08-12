# Obsidian Sync Server

CouchDB set up as a backend for the [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) plugin in Obsidian.

## What the add-on configures

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

The vault database lives in `/config/obsidian-syncserver/data` rather than the add-on's `/data` directory, so it survives a reinstall and **gets picked up by Home Assistant backups**.

If you did not set a password, the generated one is in `/config/obsidian-syncserver/admin_password`.

## Reverse proxy setup

Mobile Obsidian refuses plain HTTP, so a phone or tablet needs TLS in front of this add-on. Any proxy will do, as long as it does three things:

Pass the `Authorization` header through untouched. CouchDB authenticates every single request, so a proxy that strips or rewrites that header turns everything into a 401.

Allow WebSocket upgrades. LiveSync uses continuous replication. Without upgrade support the connection looks like it works and then just sits there.

Avoid buffering responses indefinitely, or the long-poll changes feed lags behind.

### Nginx Proxy Manager

Add a Proxy Host:

- Domain Names: whatever hostname you plan to use, say `obsidian.example.com`
- Scheme: `http`
- Forward Hostname / IP: your Home Assistant machine
- Forward Port: `5984`
- Websockets Support: on
- On the SSL tab, request or select a certificate and turn on Force SSL

Then point LiveSync at `https://obsidian.example.com`.

### Plain nginx

```nginx
location / {
    proxy_pass http://homeassistant.local:5984;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;

    # CouchDB authenticates every request
    proxy_pass_request_headers on;

    # LiveSync uses continuous replication
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    proxy_buffering off;
    proxy_read_timeout 600s;
}
```

## Troubleshooting

If the add-on stops right after starting, read the log. A malformed `database` name or a `/config` directory CouchDB cannot write to will both halt startup with a message saying which.

If LiveSync reports a network or CORS error, it is nearly always the proxy rather than CouchDB. Check the server directly first:

```bash
curl -u admin:YOURPASSWORD http://homeassistant.local:5984/obsidian
```

When that works but the plugin still fails, the proxy is either dropping the `Authorization` header or blocking the WebSocket upgrade.

If desktop syncs but mobile does not, the app does not trust your certificate. Self-signed ones generally will not cut it. The NPM version of this add-on exists partly to make that easier.

If sync connects and then stalls, WebSocket upgrade is not getting through the proxy.

To see the applied configuration:

```bash
curl -u admin:YOURPASSWORD http://homeassistant.local:5984/_node/_local/_config/cors
```

The Obsidian origins should be listed there.

## Backups

Home Assistant backs up `/config`, which covers the vault database. For a copy you can move elsewhere, use CouchDB replication or export from Fauxton at `http://<host>:5984/_utils`.
