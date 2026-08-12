# Home assistant add-on: Obsidian Sync Server

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fobsidian_syncserver_solo%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fobsidian_syncserver_solo%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fobsidian_syncserver_solo%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

Runs CouchDB as a sync backend for the [Self-hosted LiveSync](https://github.com/vrtmrz/obsidian-livesync) plugin in Obsidian.

This add-on is only the server side. Install the companion plugin in Obsidian: <https://community.obsidian.md/plugins/obsidian-livesync>

> [!IMPORTANT]
>
> - Before installing or upgrading this add-on or the obsidian livesync plugin, please back up your vault.
> - Not compatible with other synchronisation solution (including iCloud and Obsidian Sync).
> - For backups, use [Differential ZIP Backup](https://github.com/vrtmrz/diffzip).

Your vault syncs between your own devices through Home Assistant. No Obsidian Sync subscription, and the notes stay on your network.

This add-on speaks plain HTTP. Desktop Obsidian works fine with that. Mobile Obsidian does not, because it insists on a valid TLS certificate ([Easy to add on HA](https://www.home-assistant.io/blog/2017/09/27/effortless-encryption-with-lets-encrypt-and-duckdns/)). To sync a phone or tablet you need a reverse proxy in front of this add-on, or one of the other two versions:

| Add-on | TLS | Use when |
| :--- | :--- | :--- |
| Obsidian Sync Server (this one) | none | You already run a reverse proxy |
| [Obsidian Sync Server SSL](../obsidian_syncserver_ssl/README.md) | CouchDB serves HTTPS from your certificates in `/ssl` | You have certificates on the Home Assistant machine |
| [Obsidian Sync Server NPM](../obsidian_syncserver_npm/README.md) | Bundled Nginx Proxy Manager | You have no proxy and want certificate handling included |

## Installation

1. Add the repository `https://github.com/alexbelgium/hassio-addons` to Home Assistant, then install the add-on.
2. Set a password under Configuration. Leaving it blank generates one and prints it in the log on first start.
3. Start the add-on and look for `Ready.` in the log.

## Configuration

```yaml
username: admin
password: ""
database: obsidian
log_level: info
```

`username` and `password` are the CouchDB administrator credentials that the LiveSync plugin uses. A blank password gets generated on first start and saved to `/config/obsidian-syncserver/admin_password`.

`database` is the CouchDB database holding your vault. The add-on creates it if it does not exist.

`log_level` sets CouchDB log verbosity.

## Connecting Obsidian

Install Self-hosted LiveSync from Obsidian's community plugins. In its settings, pick the manual setup and fill in:

- URI: `http://<home-assistant-host>:5984`, or your proxy's HTTPS address
- Username and password: whatever you configured above
- Database name: `obsidian`, unless you changed it

Hit Test Database Connection to check it, then turn on end-to-end encryption with a passphrase. With that on, the server only ever holds ciphertext.

[DOCS.md](DOCS.md) covers reverse proxy setup and troubleshooting.

## Security

CouchDB here requires authentication on every request, so nothing is readable anonymously. Still, do not forward port 5984 to the internet. Keep it on your LAN, or put it behind a proxy that terminates TLS and does its own access control.

## Support

Create an issue on [github](https://github.com/alexbelgium/hassio-addons/issues) and tag @ToledoEM

- Obsidian Self-hosted LiveSync plugin → [github.com/vrtmrz/obsidian-livesync](https://github.com/vrtmrz/obsidian-livesync)
- CouchDB upstream → [couchdb.apache.org](https://couchdb.apache.org/)
