# Home assistant add-on: Calibre-web


I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcalibre_web%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcalibre_web%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcalibre_web%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/calibre_web/stats.png)

## About

---

[Calibre-web](https://github.com/janeczku/calibre-web) is a web app providing a clean interface for browsing, reading and downloading eBooks using an existing Calibre database. It is also possible to integrate google drive and edit metadata and your calibre library through the app itself.

This addon is based on the docker image https://github.com/linuxserver/docker-calibre-web

## Installation

---

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and adapt the software options

## Configuration

Webui can be found at <http://homeassistant:PORT> or through the sidebar using Ingress.
The default username/password is described in the startup log.
Configurations can be done through the app webUI, except for the following options.

Default name: admin
Default password: admin123

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `PGID` | int | `0` | Group ID for file permissions |
| `PUID` | int | `0` | User ID for file permissions |
| `TZ` | str | | Timezone (e.g., `Europe/London`) |
| `DOCKER_MODS` | str | | Docker modifications to apply |
| `OAUTHLIB_RELAX_TOKEN_SCOPE` | str | | OAuth token scope relaxation |
| `ingress_user` | str | | Username for ingress authentication |
| `localdisks` | str | | Local drives to mount (e.g., `sda1,sdb1,MYNAS`) |
| `networkdisks` | str | | SMB shares to mount (e.g., `//SERVER/SHARE`) |
| `cifsusername` | str | | SMB username for network shares |
| `cifspassword` | str | | SMB password for network shares |
| `cifsdomain` | str | | SMB domain for network shares |

### Example Configuration

```yaml
PGID: 0
PUID: 0
TZ: "Europe/London"
DOCKER_MODS: "linuxserver/mods:universal-calibre"
ingress_user: "admin"
localdisks: "sda1,sdb1"
networkdisks: "//192.168.1.100/books"
cifsusername: "bookuser"
cifspassword: "password123"
cifsdomain: "workgroup"
```

### Mounting Drives

This addon supports mounting both local drives and remote SMB shares:

- **Local drives**: See [Mounting Local Drives in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-Local-Drives-in-Addons)
- **Remote shares**: See [Mounting Remote Shares in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-remote-shares-in-Addons)

### Optional Calibre-Web features

Calibre-Web documents optional extras that a manual installation adds with `pip install calibreweb[metadata]` and similar. **You do not need to install anything here**: the LinuxServer base image this add-on builds on installs Calibre-Web's `requirements.txt` *and* its full `optional-requirements.txt` into the application's virtualenv, so the gdrive, gmail, goodreads, ldap, oauth, metadata, comics and kobo dependencies are all present already. Running `pip install calibreweb[...]` inside the container is not a supported way to enable them: it installs the PyPI distribution of Calibre-Web over an installation that already has those dependencies, and it can disturb the versions the base image pinned. It is also thrown away, because the Supervisor recreates the add-on container on restart.

Optional features are switched on in the Calibre-Web web interface, not in the add-on options, under `Admin` -> `Basic Configuration` -> `Feature Configuration` (for example `Enable Uploads`, `Enable Kobo sync`, `Use Goodreads`).

**Book covers.** The `Fetch Cover from URL` and `Upload Cover from Local Disk` fields only appear on a book's `Edit Metadata` page when `Enable Uploads` is ticked in `Feature Configuration` **and** the logged-in user has the `Upload` permission (`Admin` -> the user -> `Upload`). A missing Python package is not what hides them.

**Conversion, metadata embedding and the other Calibre integrations** use command-line binaries such as `ebook-convert`, `ebook-meta` and `calibredb`. Those are installed at start by the `linuxserver/mods:universal-calibre` docker mod, which is the shipped default of the `DOCKER_MODS` option. If you set `DOCKER_MODS` yourself, keep `linuxserver/mods:universal-calibre` in the list (mods are separated by `|`) or those binaries disappear.

**Other compatible Python packages** can be installed from the add-on's custom script (see the section below); `pip` there points at Calibre-Web's own virtualenv. Such a script runs on every start, and it has to, since the container's writable layer does not persist.

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **env_vars option**: Use the add-on `env_vars` option to pass extra environment variables (uppercase or lowercase names). See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## Support

Create an issue on github

## Illustration

---

![illustration](https://calibre-web.com/img/slider/artistdetails.png)

[repository]: https://github.com/alexbelgium/hassio-addons


