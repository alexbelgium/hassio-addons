# Home Assistant Add-on: Comicarr

Automated comic book and manga downloader and library manager with a modern React UI.

[Comicarr](https://comicarr.com) is a fork of Mylar3 rebuilt around a React frontend and a
FastAPI backend. You add series, and it watches for new issues, sends them to your download
client, tags them and files them into your library.

## About

- Track comic series and manga, and grab new issues as they are released
- Works with SABnzbd, NZBGet, blackhole and torrent clients
- Metadata from ComicVine and Metron, with automatic tagging
- One-command migration from an existing Mylar3 installation
- OPDS feed for third-party readers

## Installation

1. Add this repository to Home Assistant.
2. Install the **Comicarr** add-on.
3. Start the add-on and open it from the sidebar (ingress), or on port `8090` at
   `http://homeassistant:8090`.
4. Complete the first-run setup when the web interface asks for it.
5. Point Comicarr's library and download folders at a persistent location such as
   `/media/comics` and `/share/downloads`.

The first start takes longer than usual: the database migrations run against a cold SQLite
database.

## Configuration

| Option | Description |
|--------|-------------|
| `PUID` / `PGID` | Ownership applied to the add-on configuration directory. Defaults to `0` (root). See the note below before changing it. |
| `TZ` | Timezone, e.g. `Europe/Paris`. |
| `localdisks` | Local disks to mount, e.g. `sda1` or a disk label. |
| `networkdisks` | SMB shares to mount, e.g. `//192.168.1.2/comics`. Mounted under `/mnt`. |
| `cifsusername` / `cifspassword` / `cifsdomain` | Credentials for the SMB shares. |
| `smbv1` | Allow the legacy SMBv1 protocol. |
| `env_vars` | Extra environment variables passed to Comicarr. See the [wiki](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2). |

`COMICARR_LOG_LEVEL` (`0`, `1` or `2`) is a useful `env_vars` entry: it overrides the log
verbosity chosen in Settings on every restart.

With the default `PUID`/`PGID` of `0`, Comicarr runs as root, which is what lets it write to
Home Assistant's root-owned `/media` and `/share`. Setting `PUID` to any other value hands
startup to the upstream entrypoint, which creates a matching user and drops privileges — the
library and download folders then have to be writable by that user.

The web interface port is fixed at `8090`. Changing **Settings → Interface → port** has no
effect: the add-on forces `8090` on startup, because ingress and the health check are built
around it.

## Ingress and URLs

Comicarr has no url-base setting, so the add-on bundles an nginx reverse proxy that rewrites the
absolute `/assets`, `/api` and `/cache` urls in the served HTML, JavaScript and CSS onto the
ingress path, and replaces the upstream `X-Frame-Options: DENY` and `frame-ancestors 'none'`
headers, which would otherwise leave the panel blank.

Two consequences worth knowing:

- The app's client-side router does not know about the ingress prefix. It rewrites the panel's
  address to `/` shortly after loading. Everything keeps working, because every request url is
  rewritten to an absolute ingress path — but reloading the panel frame itself (rather than
  reopening it from the sidebar) shows Home Assistant instead of Comicarr.
- Two places in the app navigate with `window.location` rather than the router: finishing the
  first-run setup, and a session expiring while the dashboard is open. Both leave the panel;
  reopening Comicarr from the sidebar recovers.

External clients — OPDS readers in particular — must use the direct `http://homeassistant:8090`
url. Ingress is browser-session based, so those clients cannot authenticate through it.

Do not enable HTTPS inside Comicarr's own settings: the add-on's proxy talks plain HTTP to it on
`127.0.0.1`, and ingress would stop working.

## Data

Comicarr's `config.ini`, database, logs and cover cache live in `/config/comicarr` inside the
add-on, which Home Assistant maps to this add-on's own configuration directory —
`/addon_configs/<repository_id>_comicarr`, browsable with the Filebrowser add-on. They survive
add-on updates. That is the same layout as the upstream `./config:/config` compose volume, so an
existing installation can be copied in as is.

Comic and download folders are **not** stored there. Point them at `/media`, `/share` or a
mounted disk. The `/comics`, `/manga` and `/downloads` paths used by the upstream docker image
are not persistent in Home Assistant — do not use them.

## Support

- [Comicarr upstream project](https://github.com/frankieramirez/comicarr)
- [Add-on repository issues](https://github.com/alexbelgium/hassio-addons/issues)
