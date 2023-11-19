## &#9888; Open Issue : [🐛 [paperless_ngx] Updates are not recognised (opened 2023-07-03)](https://github.com/alexbelgium/hassio-addons/issues/889) by [@rafael298](https://github.com/rafael298)
# Home assistant add-on: Paperless NGX

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fpaperless_ngx%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fpaperless_ngx%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fpaperless_ngx%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://github.com/alexbelgium/hassio-addons/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Builder](https://github.com/alexbelgium/hassio-addons/workflows/Builder/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/paperless_ngx/stats.png)

## About

[Paperless NGX](https://github.com/paperless-ngx/paperless-ngx) is a document management system that transforms your physical documents into a searchable online archive so you can keep, well, less paper.

## Configuration

Default username:password is admin:admin. Once logged in, you can change it from within the administration panel.

Options can be configured through two ways :

- Addon options

```yaml
PGID: user
GPID: user
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. ex. sda1, sdb1, MYNAS...
networkdisks: "<//SERVER/SHARE>" # list of smbv2/3 servers to mount (optional)
cifsusername: "username" # smb username (optional)
cifspassword: "password" # smb password (optional)
CONFIG_LOCATION: Location of the config.yaml (see below)
OCRLANG: eng fra #Any language can be set from this page (always three letters) [here](https://tesseract-ocr.github.io/tessdoc/Data-Files#data-files-for-version-400-november-29-2016).
TZ: Europe/Paris # Sets a specific timezone
```

- Config.yaml

Custom env variables can be added to the config.yaml file referenced in the addon options. Full env variables can be found here : https://paperless-ngx.readthedocs.io/en/latest/configuration.html. It must be entered in a valid yaml format, that is verified at launch of the addon.

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

## Integration with HA

No specific integration, it is a self hosted system

## Support

Create an issue on github

## Illustration

---

![illustration](https://paperless-ngx.readthedocs.io/en/latest/_images/documents-smallcards.png)
