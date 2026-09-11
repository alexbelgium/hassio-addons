# Home assistant add-on: Obsidian Sync Server NPM

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fobsidian_syncserver_npm%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fobsidian_syncserver_npm%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fobsidian_syncserver_npm%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

Runs CouchDB as a sync backend for the [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) plugin in Obsidian, with [Nginx Proxy Manager](https://nginxproxymanager.com/) bundled in to handle TLS.

This add-on is only the server side. Install the companion plugin in Obsidian: <https://community.obsidian.md/plugins/obsidian-livesync>

> [!IMPORTANT]
>
> - Before installing or upgrading this add-on or the obsidian livesync plugin, please back up your vault.
> - Not compatible with other synchronisation solution (including iCloud and Obsidian Sync).
> - For backups, use [Differential ZIP Backup](https://github.com/vrtmrz/diffzip).

Your vault syncs between your own devices through Home Assistant. No Obsidian Sync subscription, and the notes stay on your network.

This version has everything mobile Obsidian needs in one add-on. NPM requests and renews the certificates and proxies HTTPS through to CouchDB. Pick it if you do not already run a reverse proxy.

| Add-on | TLS | Use when |
| :--- | :--- | :--- |
| [Obsidian Sync Server](../obsidian_syncserver_solo/README.md) | none | You already run a reverse proxy |
| [Obsidian Sync Server SSL](../obsidian_syncserver_ssl/README.md) | CouchDB serves HTTPS from your certificates in `/ssl` | You have certificates on the Home Assistant machine |
| Obsidian Sync Server NPM (this one) | Bundled Nginx Proxy Manager | You have no proxy and want certificate handling included |

Note that this add-on binds ports 80, 81 and 443. If you already run the Nginx Proxy Manager + Static Web Server add-on, or anything else on those ports, only one of them can be running at a time. In that case use the plain [Obsidian Sync Server](../obsidian_syncserver_solo/README.md) and add a proxy host to the NPM you already have.

## Ports

| Port | Use |
| :--- | :--- |
| 443 | HTTPS, point Obsidian here |
| 81 | Nginx Proxy Manager admin UI |
| 80 | HTTP, certificate validation and redirect |
| 5984 | CouchDB directly, for desktop or local tools |

## Installation

1. Add the repository `https://github.com/alexbelgium/hassio-addons` to Home Assistant, then install the add-on.
2. Set a password under Configuration. Leaving it blank generates one and prints it in the log on first start.
3. Start the add-on and look for `Ready.` in the log.
4. Open the NPM admin UI on port 81. The default login is `admin@example.com` with password `changeme`, and NPM makes you change both on first login. Do that now rather than later.

## Getting a real certificate

Port 443 answers out of the box, but with a self-signed certificate that mobile Obsidian will reject. To fix that:

1. In the NPM admin UI, go to SSL Certificates, then Add SSL Certificate, then Let's Encrypt.
2. Enter the domain name pointing at your Home Assistant machine, plus your email.
3. If the domain has no public IP, tick Use a DNS Challenge and pick your DNS provider.
4. Once the certificate is issued, go to Hosts, then Proxy Hosts, then Add Proxy Host:
   - Domain Names: your domain
   - Scheme: `http`
   - Forward Hostname / IP: `127.0.0.1`
   - Forward Port: `5984`
   - Websockets Support: on. LiveSync will not sync without it.
   - On the SSL tab, select your certificate and turn on Force SSL.

## Configuration

```yaml
username: admin
password: ""
database: obsidian
log_level: info
```

`username` and `password` are the CouchDB administrator credentials that the LiveSync plugin uses, separate from the NPM admin login. A blank password gets generated on first start and saved to `/config/obsidian-syncserver/admin_password`.

`database` is the CouchDB database holding your vault. The add-on creates it if it does not exist.

`log_level` sets CouchDB log verbosity.

## Connecting Obsidian

Install Self-hosted LiveSync from Obsidian's community plugins. In its settings, pick the manual setup and fill in:

- URI: `https://your-domain`
- Username and password: the CouchDB credentials above
- Database name: `obsidian`, unless you changed it

Hit Test Database Connection to check it, then turn on end-to-end encryption with a passphrase. With that on, the server only ever holds ciphertext.

[DOCS.md](DOCS.md) covers troubleshooting.

## Security

CouchDB requires authentication on every request, and NPM's admin UI has its own login that you have to change the first time you use it. Keep this on your LAN unless you have deliberately set up remote access.

## Support

For problems with this add-on (not the upstream CouchDB or Nginx Proxy Manager software), create an issue on [github](https://github.com/alexbelgium/hassio-addons/issues) and tag @ToledoEM

- Obsidian Self-hosted LiveSync plugin → [github.com/vrtmrz/obsidian-livesync](https://github.com/vrtmrz/obsidian-livesync)
- CouchDB upstream → [couchdb.apache.org](https://couchdb.apache.org/)
- Nginx Proxy Manager upstream → [github.com/NginxProxyManager/nginx-proxy-manager](https://github.com/NginxProxyManager/nginx-proxy-manager)
