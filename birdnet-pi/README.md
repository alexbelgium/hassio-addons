## &#9888; Open Issue : [🐛 [birdnet-pi] birds.db not written/used (opened 2024-05-01)](https://github.com/alexbelgium/hassio-addons/issues/1369) by [@frostworx](https://github.com/frostworx)
# Home assistant add-on: birdnet-pi

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbirdnet-pi%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbirdnet-pi%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbirdnet-pi%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/birdnet-pi/stats.png)

## About

---

[birdnet-pi](https://github.com/Nachtzuster/BirdNET-Pi) is an AI solution for continuous avian monitoring and identification originally developed by @mcguirepr89 on github (https://github.com/mcguirepr89/BirdNET-Pi), whose work is continued by @Nachtzuster and other developers on an active fork (https://github.com/Nachtzuster/BirdNET-Pi)

Features of the addon :
- Robust base image provided by [linuxserver](https://github.com/linuxserver/docker-baseimage-debian)
- Working docker system thanks to https://github.com/gdraheim/docker-systemctl-replacement
- Uses HA pulseaudio server
- Uses HA tmpfs to store temporary files in ram and avoid disk wear
- Exposes all config files to /config to allow remanence and easy access
- Allows to modify the location of the stored bird songs (preferably to an external hdd)
- Supports ingress, to allow secure remote access without exposing ports

## Configuration

Install, then start the addon a first time
Webui can be found at <http://homeassistant:80>.

You'll need a microphone : either use one connected to HA or the audio stream of a rstp camera.

Options can be configured through three ways :

- Addon options

```yaml
TZ: Etc/UTC specify a timezone to use, see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
BIRDSONGS_FOLDER: folder to store birdsongs file # It should be an ssd if you want to avoid clogging of analysis
BIRDS_ONLINE_INFO: uses either allaboutbird (US birds in english) or ebird (universal and translated) to provide online information
pi_password: set the user password
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. ex. sda1, sdb1, MYNAS...
networkdisks: "//SERVER/SHARE" # optional, list of smb servers to mount, separated by commas
cifsusername: "username" # optional, smb username, same for all smb shares
cifspassword: "password" # optional, smb password
cifsdomain: "domain" # optional, allow setting the domain for the smb share
```

- Config.yaml
Additional variables can be configured using the config.yaml file found in /config/db21ed7f_birdnet-pi/config.yaml using the Filebrowser addon

- Config_env.yaml
Additional environment variables can be configured there

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

## Integration with HA

You can use apprise to send notifications with mqtt, then act on those using HomeAssistant
Further informations : https://wander.ingstar.com/projects/birdnetpi.html

## Common issues

Not yet available

## Support

Create an issue on github

---

![illustration](https://raw.githubusercontent.com/tphakala/birdnet-pi/main/doc/birdnet-pi-dashboard.webp)
