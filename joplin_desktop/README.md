# Home assistant add-on: Joplin Desktop


I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fjoplin_desktop%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fjoplin_desktop%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fjoplin_desktop%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/joplin_desktop/stats.png)

## About

[Joplin](https://joplinapp.org) is an open source note-taking and to-do application. This add-on runs the full Joplin **desktop** app and streams it to your browser with Selkies, so you can use it from any device without installing anything.

This addon is based on the docker image <https://github.com/linuxserver/docker-joplin>

If you only need to sync your notes between your own Joplin apps, the [Joplin Server](https://github.com/alexbelgium/hassio-addons/tree/master/joplin) add-on is lighter. The two work together: point this desktop app at your Joplin Server in Joplin's synchronisation settings.

Only amd64 is supported, because Joplin does not publish a Linux arm64 build.

## Configuration

The recommended way in is ingress (the sidebar panel). You can also enable the https port 3001 in the add-on network settings and open <https://homeassistant:3001>; the browser streaming features need HTTPS, so do not use the plain http port 3000 directly — it is only meant to sit behind your own TLS reverse proxy. If you open a port, set `PASSWORD`: the web interface then asks for user `abc` and that password. This basic authentication is only suitable on a trusted local network; for access from the internet use a reverse proxy with stronger authentication.

Joplin's profile (notes, settings, plugins) is stored in `data_location`, by default `/config/data`, which is the add-on's own folder under `/addon_configs/` on your Home Assistant host. It is kept across restarts and updates and included in backups.

Use the add-on `env_vars` option to pass extra environment variables (uppercase or lowercase names). See <https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2> for details.

```yaml
PUID: 1000 # user id of the desktop user and owner of the data folder
PGID: 1000 # group id of the desktop user
TZ: Europe/Paris # timezone, Country/City according to https://manpages.ubuntu.com/manpages/trusty/man3/DateTime::TimeZone::Catalog.3pm.html
KEYBOARD: fr-fr-azerty # keyboard layout
PASSWORD: "mypassword" # basic authentication on the web interface (user abc). Set it if you open port 3001; trusted local networks only
DRINODE: /dev/dri/renderD128 # GPU device used for rendering and encoding, if the default does not work
data_location: /config/data # where Joplin's profile is stored; must be in /config, /share, /data or /mnt
additional_apps: "" # comma-separated apt packages to install at every start (not persistent otherwise)
use_own_certs: false # use your own certificates from /ssl for the https port 3001
certfile: fullchain.pem # certificate file in /ssl
keyfile: privkey.pem # key file in /ssl
DNS_server: 8.8.8.8 # keep blank to use your router's DNS
localdisks: sda1 # put the hardware name of your drive to mount separated by commas, or its label. ex. sda1, sdb1, MYNAS... Add a folder to mount only it, ex. MYNAS/public mounts at /mnt/MYNAS/public
networkdisks: "//SERVER/SHARE" # optional, list of smb servers to mount, separated by commas
cifsusername: "username" # optional, smb username, same for all smb shares
cifspassword: "password" # optional, smb password
cifsdomain: "domain" # optional, allow setting the domain for the smb share
```

### Useful upstream variables

These are read by the LinuxServer Selkies base image and can be set through `env_vars`. The full list is at <https://docs.linuxserver.io/images/docker-joplin>.

| Variable | Effect |
| --- | --- |
| `RESTART_APP` | `true` restarts Joplin automatically if its window is closed |
| `NO_DECOR` | any value removes window decorations, so Joplin fills the browser like a web app |
| `NO_FULL` | any value stops the window manager from maximising the window |
| `HARDEN_DESKTOP` | `true` disables the terminal, sudo, xdg-open and Selkies file transfers, keeping only Joplin |
| `SELKIES_AUDIO_ENABLED`, `SELKIES_MICROPHONE_ENABLED` | `false` disables audio or microphone streaming |
| `SELKIES_FRAMERATE` | streaming frame rate cap, e.g. `30` |

## Installation


The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and adapt the software options

## Support

Create an issue on github
