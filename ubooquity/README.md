# Home assistant add-on: Ubooquity

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fubooquity%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fubooquity%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fubooquity%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/ubooquity/stats.png)

## About

---

[Ubooquity by vaemendis](https://vaemendis.net/ubooquity/) is a free, lightweight and easy-to-use home server for your comics and ebooks developed . This addon is based on the [docker image](https://github.com/linuxserver/docker-ubooquity) from [linuxserver.io](https://www.linuxserver.io/).

Ubooquity supports many types of files, with a preference for ePUB, CBZ, CBR and PDF files. Metadata from library management software Calibre and ComicRack are also supported. Ubooquity lets you create user accounts and set access rights for each shared folder.

This addons has several configurable options :

- allowing to mount local external drive, or smb share from the addon (decreases performance)
- **VERY IMPORTANT, CAN CRASH SYSTEM** : Setting of the maximum RAM usage for java. The quantity of memory allocated to Ubooquity depends on the hardware your are running it on. If this quantity is too small, you might sometime saturate it with when performing memory intensive operations and you'll get "java.lang.OutOfMemoryError: Java heap space errors". If the quantity allocated is too high for your system, it will crash home assistant and you'll need to manually reboot. Value is a number of megabytes ( put just a number, without MB).

It is recommended to enable OPDS server from option, then you can connect to your comics/eBook server from a mobile app (I use [Chunky](https://apps.apple.com/fr/app/chunky-comic-reader/id663567628) on iOS (paid), [Kuboo](https://play.google.com/store/apps/details?id=com.sethchhim.kuboo&hl=fr&gl=US) on android (free))

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI, set an admin password and adapt the administration options

## Configuration

Webui can be found at <http://homeassistant:PORT> or through the sidebar using Ingress.
The default username/password is described in the startup log.
Configurations can be done through the app webUI, except for the following options.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `PGID` | int | `0` | Group ID for file permissions |
| `PUID` | int | `0` | User ID for file permissions |
| `TZ` | str | | Timezone (e.g., `Europe/London`) |
| `maxmem` | int | `200` | Maximum RAM usage for Java (MB) - **CRITICAL SETTING** |
| `ssl` | bool | `false` | Enable HTTPS for the web interface |
| `certfile` | str | `fullchain.pem` | Path for the TLS certificate |
| `keyfile` | str | `privkey.pem` | Path for the TLS key file |
| `theme` | list | `default` | Theme selection (default/comixology2/plextheme-master) |
| `localdisks` | str | | Local drives to mount (e.g., `sda1,sdb1,MYNAS`) |
| `networkdisks` | str | | SMB shares to mount (e.g., `//SERVER/SHARE`) |
| `cifsusername` | str | | SMB username for network shares |
| `cifspassword` | str | | SMB password for network shares |
| `cifsdomain` | str | | SMB domain for network shares |
| `smbv1` | bool | `false` | Enable SMB v1 protocol |

**Important**: The `maxmem` setting controls Java heap space. Too low causes OutOfMemoryError; too high can crash Home Assistant. Default 200MB for RPi3B+, 512MB recommended for systems with 2GB+ RAM.

### Example Configuration

```yaml
PGID: 0
PUID: 0
TZ: "Europe/London"
maxmem: 512
ssl: false
certfile: "fullchain.pem"
keyfile: "privkey.pem"
theme: "comixology2"
localdisks: "sda1,sdb1"
networkdisks: "//192.168.1.100/comics,//nas.local/books"
cifsusername: "comicuser"
cifspassword: "password123"
cifsdomain: "workgroup"
smbv1: false
```

### Mounting Drives

This addon supports mounting both local drives and remote SMB shares:

- **Local drives**: See [Mounting Local Drives in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-Local-Drives-in-Addons)
- **Remote shares**: See [Mounting Remote Shares in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-remote-shares-in-Addons)

Network disks are mounted to `/mnt/share_name`.

## Support

Create an issue on the [repository github][repository], or ask on the [home assistant thread](https://community.home-assistant.io/t/home-assistant-addon-ubooquity/283811)

## Illustration

---

![alt text](https://vaemendis.net/ubooquity/data/images/screenshots/books_library.jpg)

[repository]: https://github.com/alexbelgium/hassio-addons
