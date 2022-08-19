## &#9888; Open Issue : [🐛 [Transmission Openvpn] testaze file leftover after CIFS check (opened 2022-08-19)](https://github.com/alexbelgium/hassio-addons/issues/431) by [@almico](https://github.com/almico)
# Home assistant add-on: Transmission

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftransmission%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftransmission%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftransmission%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://github.com/alexbelgium/hassio-addons/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Builder](https://github.com/alexbelgium/hassio-addons/workflows/Builder/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/dark/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)
[![Stargazers repo roster for @alexbelgium/hassio-addons](https://git-lister.onrender.com/api/stars/alexbelgium/hassio-addons?limit=30)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

Transmission is a bittorrent client.
This addon is based on the [docker image](https://github.com/linuxserver/transmission) from linuxserver.io.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

## Configuration

Options :

```yaml
download_dir: "/share/downloads" # where the files will be saved after download
incomplete_dir: "/share/incomplete" # where the files are saved during download
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. Ex: sda1, sdb1, MYNAS...
networkdisks: "<//SERVER/SHARE>" # list of smbv2/3 servers to mount, '' if none
cifsusername: "<username>" # smb username
cifspassword: "<password>" # smb password
```

Complete transmission options are in /share/transmission (make sure addon is stopped before modifying it as Transmission writes its ongoing values when stopping and could erase your changes)

Webui can be found at `<your-ip>:9091`.

[repository]: https://github.com/alexbelgium/hassio-addons
