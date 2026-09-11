# Obsidian Sync Server SSL

CouchDB set up as a backend for the [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) plugin in Obsidian, serving HTTPS directly from certificates in `/ssl`.

## Ports

| Port | Protocol | Use |
| :--- | :--- | :--- |
| 5984 | HTTP | Desktop Obsidian, Fauxton, local tools |
| 6984 | HTTPS | Mobile Obsidian, anything needing TLS |

Both are served at once. HTTPS only appears when `ssl` is on and the certificate passes its checks.

## Certificates

Certificates come from `/ssl`, mapped read-only. The Let's Encrypt and DuckDNS add-ons are the usual things writing them there.

This add-on never renews anything. It only reads. When the certificate expires the add-on refuses to start until whatever issued it renews the file. That is deliberate: quietly serving an expired certificate produces a sync failure on the phone with no explanation, which is far worse to track down than a stopped add-on with a clear message in the log.

### What gets checked before startup

| Check | The failure message names |
| :--- | :--- |
| File present and readable | The exact path it tried |
| Valid PEM certificate | The file that would not parse |
| Valid PEM private key | The file that would not parse |
| Not expired | The expiry date |
| Certificate matches key | Both filenames |

A good start logs the covered hostnames and the expiry date:

```
Certificate covers: obsidian.example.com
Obsidian must reach this server by one of those names, or it will reject the certificate.
TLS enabled on port 6984 (certificate valid until Nov  3 12:00:00 2026 GMT)
```

The hostname list is there to help you spot a mismatch, not as a hard check. Reaching the server by some other name is legitimate, so the add-on still starts.

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

## Troubleshooting

If the add-on will not start and the log mentions the certificate, the message names the specific problem: missing file, unparseable PEM, expired, or a certificate and key that do not belong together. Fix the file in `/ssl`, or set `ssl` to `false` to run HTTP only while you sort it out.

For an expired certificate, renew it with whatever add-on issues it, then restart this one. Worth checking that the renewal is actually scheduled. A certificate that lapsed months ago usually means nothing is renewing it at all.

If desktop syncs but mobile does not, suspect the certificate. Check that the phone reaches the server by a hostname the certificate covers rather than by IP, and that the issuer is one the phone trusts. Self-signed certificates normally get rejected.

To confirm what is actually being served:

```bash
openssl s_client -connect yourhost:6984 </dev/null | openssl x509 -noout -subject -dates
```

To see the applied configuration:

```bash
curl -u admin:YOURPASSWORD https://yourhost:6984/_node/_local/_config/cors
```

If LiveSync reports a CORS or network error over HTTPS, check the plain HTTP port first:

```bash
curl -u admin:YOURPASSWORD http://homeassistant.local:5984/obsidian
```

HTTP working while HTTPS does not points at the certificate rather than CouchDB.

## Backups

Home Assistant backs up `/config`, which covers the vault database. For a copy you can move elsewhere, use CouchDB replication or export from Fauxton at `https://<host>:6984/_utils`.
