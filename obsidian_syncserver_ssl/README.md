# Home assistant add-on: Obsidian Sync Server SSL

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fobsidian_syncserver_ssl%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fobsidian_syncserver_ssl%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fobsidian_syncserver_ssl%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

Runs CouchDB as a sync backend for the [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) plugin in Obsidian, serving HTTPS from certificates you already have.

This add-on is only the server side. Install the companion plugin in Obsidian: <https://community.obsidian.md/plugins/obsidian-livesync>

> [!IMPORTANT]
>
> - Before installing or upgrading this add-on or the obsidian livesync plugin, please back up your vault.
> - Not compatible with other synchronisation solution (including iCloud and Obsidian Sync).
> - For backups, use [Differential ZIP Backup](https://github.com/vrtmrz/diffzip).

Your vault syncs between your own devices through Home Assistant. No Obsidian Sync subscription, and the notes stay on your network.

This version serves HTTPS on port 6984 using certificates from `/ssl`, so mobile Obsidian can sync without a separate reverse proxy ([Easy to add on HA](https://www.home-assistant.io/blog/2017/09/27/effortless-encryption-with-lets-encrypt-and-duckdns/)).

| Add-on | TLS | Use when |
| :--- | :--- | :--- |
| [Obsidian Sync Server](../obsidian_syncserver_solo/README.md) | none | You already run a reverse proxy |
| Obsidian Sync Server SSL (this one) | CouchDB serves HTTPS from your certificates in `/ssl` | You have certificates on the Home Assistant machine |
| [Obsidian Sync Server NPM](../obsidian_syncserver_npm/README.md) | Bundled Nginx Proxy Manager | You have no proxy and want certificate handling included |

## What you need first

A certificate and private key in `/ssl` on the Home Assistant machine. The Let's Encrypt and DuckDNS add-ons both put them there. This add-on only reads them. It never requests or renews anything.

A self-signed certificate usually will not satisfy mobile Obsidian, which wants one it already trusts.

## Installation

1. Add the repository `https://github.com/alexbelgium/hassio-addons` to Home Assistant, then install the add-on.
2. Set a password under Configuration. Leaving it blank generates one and prints it in the log on first start.
3. Check that `certfile` and `keyfile` match the filenames sitting in `/ssl`.
4. Start the add-on. The log should show `TLS enabled on port 6984` and then `Ready.`

## Configuration

```yaml
username: admin
password: ""
database: obsidian
ssl: true
certfile: fullchain.pem
keyfile: privkey.pem
log_level: info
```

`username` and `password` are the CouchDB administrator credentials that the LiveSync plugin uses. A blank password gets generated on first start and saved to `/config/obsidian-syncserver/admin_password`.

`database` is the CouchDB database holding your vault. The add-on creates it if it does not exist.

`ssl` turns HTTPS on port 6984 on or off. With it off you get HTTP only, and mobile sync will not work.

`certfile` and `keyfile` are filenames inside `/ssl`.

`log_level` sets CouchDB log verbosity.

## Certificate checks

A broken certificate shows up on the client as an unexplained connection failure, which is miserable to debug. So the add-on checks the certificate before it starts and refuses to run if the file is missing, unreadable, not valid PEM, expired, or does not match the private key. Whichever it is, the log says so.

On a good start it prints the hostnames the certificate covers and the expiry date.

Obsidian has to reach the server by a name the certificate covers. Connecting by IP address when the certificate lists only DNS names will fail.

## Connecting Obsidian

Install Self-hosted LiveSync from Obsidian's community plugins. In its settings, pick the manual setup and fill in:

- URI: `https://<hostname-on-your-certificate>:6984`
- Username and password: whatever you configured above
- Database name: `obsidian`, unless you changed it

Hit Test Database Connection to check it, then turn on end-to-end encryption with a passphrase. With that on, the server only ever holds ciphertext.

[DOCS.md](DOCS.md) covers troubleshooting.

## Security

CouchDB here requires authentication on every request. Keep this on your LAN unless you have deliberately set up remote access.
