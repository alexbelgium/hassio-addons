# Home assistant add-on: Nextcloud

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnextcloud%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnextcloud%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnextcloud%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://github.com/alexbelgium/hassio-addons/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Builder](https://github.com/alexbelgium/hassio-addons/workflows/Builder/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Uses elasticsearch][elasticsearch-shield]

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

## About

Various tweaks and configuration options addition.
Inital fork from version : https://github.com/haberda/hassio_addons
This addon is based on the [docker image](https://github.com/linuxserver/docker-nextcloud) from linuxserver.io.

## Configuration

```yaml
PGID/PUID: 1000 #allows setting user.
trusted_domains: your-domain.com #allows to select the trusted domains. Domains not in this lis will be removed, except for the first one used in the initial configuration.
OCR: false #set to true to install tesseract-ocr capability.
OCRLANG: fra,eng #Any language can be set from this page (always three letters) [here](https://tesseract-ocr.github.io/tessdoc/Data-Files#data-files-for-version-400-november-29-2016).
data_directory: path for the main data directory. Defaults to `/share/nextcloud`.
use_own_certs: true/false #if true, use the certfile and keyfile specified
certfile: fullchain.pem #ssl certificate, must be located in /ssl
keyfile: privkey.pem #sslkeyfile, must be located in /ssl
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. Ex: sda1, sdb1, MYNAS...
networkdisks: "//SERVER/SHARE" # optional, list of smbv2/3 servers to mount, separated by commas
cifsusername: "username" # optional, smb username, same for all smb shares
cifspassword: "password" # optional, smb password, same for all smb shares)
```

Webui can be found at `<your-ip>:port`.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Go to the webui, where you will create your username, password, and database (if using mariadb, infos are in the log)
1. Restart the addon, to apply any option that should be applied

## HA integration

See this component : https://www.home-assistant.io/integrations/nextcloud/

[repository]: https://github.com/alexbelgium/hassio-addons
[elasticsearch-shield]: https://img.shields.io/badge/Elasticsearch-optional-blue.svg?logo=elasticsearch
