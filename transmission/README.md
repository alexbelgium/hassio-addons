## &#9888; Open Issue : [🐛 [transmission-openvpn] Addon fails to start due to new permission requirements (opened 2024-12-13)](https://github.com/alexbelgium/hassio-addons/issues/1666) by [@santaryan](https://github.com/santaryan)
## &#9888; Open Issue : [🐛 [transmission] transmission-web-control not available (opened 2024-12-13)](https://github.com/alexbelgium/hassio-addons/issues/1668) by [@bilak](https://github.com/bilak)
## &#9888; Open Issue : [🐛 [Transmission] Disk is mounted, however unable to write in the shared disk (opened 2024-12-16)](https://github.com/alexbelgium/hassio-addons/issues/1673) by [@redb0](https://github.com/redb0)

# Home assistant add-on: Transmission

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftransmission%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftransmission%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftransmission%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/transmission/stats.png)

## About

Transmission is a bittorrent client.
This addon is based on the [docker image](https://github.com/linuxserver/docker-transmission) from linuxserver.io.

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
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. ex. sda1, sdb1, MYNAS...
networkdisks: "<//SERVER/SHARE>" # list of smbv2/3 servers to mount, '' if none
cifsusername: "<username>" # smb username
cifspassword: "<password>" # smb password
```

Complete transmission options are in /share/transmission (make sure addon is stopped before modifying it as Transmission writes its ongoing values when stopping and could erase your changes)

Webui can be found at `<your-ip>:9091`.

## Issues

# If settings.json gets reseted in the log https://github.com/alexbelgium/hassio-addons/issues/1269
- Install the Filebrowser addon
- Delete the folders /homeassistant/addons_config/transmission and /homeassistant/addons_config/transmission-ls

[repository]: https://github.com/alexbelgium/hassio-addons
