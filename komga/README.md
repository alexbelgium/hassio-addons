# Home Assistant Add-on: Komga

Free and open source comics/mangas media server.

[Komga](https://komga.org) organizes your comics, mangas, BDs, magazines and ebooks, serves them
through a web reader, and exposes OPDS, Kobo sync and a REST API for third-party readers
(Tachiyomi/Mihon, Panels, Chunky, ...).

## About

- Browse and read CBZ, CBR, PDF and EPUB files from any browser
- Import metadata, edit series/books, build collections and read lists
- Multi-user, with per-user library restrictions and age ratings
- OPDS v1/v2, Kobo sync, and a documented REST API

## Installation

1. Add this repository to Home Assistant.
2. Install the **Komga** add-on.
3. Start the add-on and open it from the sidebar (ingress), or on port `25600` at
   `http://homeassistant:25600/komga`.
4. Create the initial user account when the web interface asks for it.
5. Add a library pointing at your comics, for example `/media/comics` or `/share/comics`.

The first start takes longer than usual: Komga is a JVM application and builds its database and
search index on first boot.

## Configuration

| Option | Description |
|--------|-------------|
| `PUID` / `PGID` | Ownership applied to the add-on configuration directory. Defaults to `0` (root). |
| `TZ` | Timezone, e.g. `Europe/Paris`. |
| `localdisks` | Local disks to mount, e.g. `sda1` or a disk label. |
| `networkdisks` | SMB shares to mount, e.g. `//192.168.1.2/comics`. Mounted under `/mnt`. |
| `cifsusername` / `cifspassword` / `cifsdomain` | Credentials for the SMB shares. |
| `smbv1` | Allow the legacy SMBv1 protocol. |
| `env_vars` | Extra environment variables passed to Komga. See the [wiki](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2). |

Any Komga setting can be passed through `env_vars` using the upstream naming, see the
[Komga configuration options](https://komga.org/docs/installation/configuration/). Two common ones:

- `JAVA_TOOL_OPTIONS` = `-Xmx1g` — cap the JVM heap on small machines.
- `KOMGA_LIBRARIES_SCAN_CRON` — change the automatic library scan schedule.

## Ingress and URLs

Komga is served from the `/komga` subpath so that it works behind Home Assistant ingress:

- from the Home Assistant sidebar: ingress, no extra setup
- directly: `http://homeassistant:25600/komga`

External clients — OPDS readers, Kobo sync, Tachiyomi/Mihon, Panels — must use the direct
`http://homeassistant:25600/komga` url. Ingress is browser-session based, so those clients cannot
authenticate through it.

Do not override `SERVER_SERVLET_CONTEXTPATH` through `env_vars`: ingress is built around the
`/komga` path and changing it breaks the sidebar panel.

## Data

Komga's database, logs and search index are stored in the add-on configuration directory
(`/addon_configs/xxx-komga`), so they survive add-on updates. Libraries stay where you put them,
under `/media`, `/share` or a mounted disk.

## Support

- [Komga upstream project](https://github.com/gotson/komga)
- [Add-on repository issues](https://github.com/alexbelgium/hassio-addons/issues)
