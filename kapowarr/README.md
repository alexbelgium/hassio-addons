# Home Assistant Add-on: Kapowarr

Build and manage a comic book library, fitting in the \*arr suite of software.

[Kapowarr](https://casvt.github.io/Kapowarr/) tracks the volumes you own, finds the issues you are
missing, downloads them through GetComics and your download clients, and keeps the files renamed
and converted the way you want them.

## About

- Import an existing comic collection and match it against ComicVine metadata
- Monitor volumes and automatically search for missing issues
- Direct downloads and Mega links, plus torrent and Usenet clients
- Automatic renaming, converting and file management

## Installation

1. Add this repository to Home Assistant.
2. Install the **Kapowarr** add-on.
3. Start the add-on and open it from the sidebar (ingress), or on port `5656` at
   `http://homeassistant:5656/kapowarr` — note the `/kapowarr` suffix, see *Ingress and URLs* below.
4. Enter a ComicVine API key under *Settings > Metadata*; Kapowarr cannot search without one.
5. Add a root folder under *Settings > Media Management*, for example `/media/comics` or
   `/share/comics`.

## Configuration

| Option | Description |
|--------|-------------|
| `PUID` / `PGID` | Ownership applied to the add-on configuration directory, and the user Kapowarr runs as. Defaults to `0` (root). |
| `TZ` | Timezone, e.g. `Europe/Paris`. |
| `localdisks` | Local disks to mount, e.g. `sda1` or a disk label. |
| `networkdisks` | SMB shares to mount, e.g. `//192.168.1.2/comics`. Mounted under `/mnt`. |
| `cifsusername` / `cifspassword` / `cifsdomain` | Credentials for the SMB shares. |
| `smbv1` | Allow the legacy SMBv1 protocol. |
| `env_vars` | Extra environment variables passed to Kapowarr. See the [wiki](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2). |

Everything else — root folders, download clients, naming, the ComicVine key — is configured in
Kapowarr's own web interface, not in the add-on options.

The *host*, *port* and *URL base* fields under *Settings > General* are reserved by the add-on.
The URL base is set back to `/kapowarr` every time the add-on starts, because the sidebar panel is
built around it; changing the host or port stops the add-on from reaching Kapowarr at all.

## Ingress and URLs

Kapowarr is served from the `/kapowarr` subpath so that it works behind Home Assistant ingress:

- from the Home Assistant sidebar: ingress, no extra setup
- directly: `http://homeassistant:5656/kapowarr` — `http://homeassistant:5656/` on its own returns
  a 404, the subpath is not optional

External clients that talk to Kapowarr's API must use the direct
`http://homeassistant:5656/kapowarr` url. Ingress is browser-session based, so they cannot
authenticate through it.

## Data

Kapowarr's database (`Kapowarr.db`) and logs live in `/config` inside the add-on, which Home
Assistant maps to this add-on's own configuration directory —
`/addon_configs/<repository_id>_kapowarr`, browsable with the Filebrowser add-on. They survive
add-on updates.

Temporary downloads go to `/config/temp_downloads` by default, so an interrupted download is not
lost when the add-on restarts. That directory is on the Home Assistant data disk: if space there is
tight, point *Settings > Download > Direct download temporary folder* at somewhere roomier such as
`/share/kapowarr_downloads` or a disk mounted through `localdisks`.

Your comics themselves stay where you put them, under `/media`, `/share` or a mounted disk.

## Support

- [Kapowarr upstream project](https://github.com/Casvt/Kapowarr)
- [Kapowarr documentation](https://casvt.github.io/Kapowarr/)
- [Add-on repository issues](https://github.com/alexbelgium/hassio-addons/issues)
