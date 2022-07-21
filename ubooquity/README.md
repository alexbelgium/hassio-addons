# Home assistant add-on: Ubooquity

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fubooquity%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fubooquity%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fubooquity%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://github.com/alexbelgium/hassio-addons/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Builder](https://github.com/alexbelgium/hassio-addons/workflows/Builder/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

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

---

The default username/password : described in the startup log.
Configurations can be done through the app webUI, except for the following options

Network disk is mounted to /mnt/share name

```yaml
GUID: user # https://docs.linuxserver.io/general/understanding-puid-and-pgid
GPID: user # https://docs.linuxserver.io/general/understanding-puid-and-pgid
maxmem: 200 # IMPORTANT read above. 200 is default for rpi3b+ ; 512 recommended if more 2gb RAM.
networkdisks: "<//SERVER/SHARE>" # list of smbv2/3 servers to mount (optional)
cifsusername: "username" # smb username (optional)
cifspassword: "password" # smb password (optional)
smbv1: false # Should smbv1 be used instead of 2.1+?
```

## Support

Create an issue on the [repository github][repository], or ask on the [home assistant thread](https://community.home-assistant.io/t/home-assistant-addon-ubooquity/283811)

## Illustration

---

![alt text](https://vaemendis.net/ubooquity/data/images/screenshots/books_library.jpg)

[repository]: https://github.com/alexbelgium/hassio-addons
