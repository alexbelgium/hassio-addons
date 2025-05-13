## &#9888; Open Issue : [🐛 [navidrome] issue using network share, Unable to apply new capability set (opened 2025-05-04)](https://github.com/alexbelgium/hassio-addons/issues/1859) by [@zerovox](https://github.com/zerovox)
# Home assistant add-on: Navidrome

[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)
[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%navidrome%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%navidrome%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%navidrome%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20Paypal-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/navidrome/stats.png)

## About

Various tweaks and configuration options addition.
This addon is based on the [docker image](https://hub.docker.com/r/deluan/navidrome).

## Configuration

see https://www.navidrome.org/docs/usage/configuration-options/#available-options

```yaml
    "base_url": "localhost",         # Base URL to configure Navidrome behind a proxy
    "music_folder": "/data/music",   # Folder where your music library is stored. Can be read-only
    "data_folder": "/data/data",     # Folder to store application data (DB)
    "log_level": "info",             # Log level. Useful for troubleshooting. Possible values: error, warn, info, debug, trace
    "certfile": "fullchain.pem",     # Path for the TLS certificate
    "keyfile": "privkey.pem",        # Path for the TLS key file
    "ssl": false                     # should the app use https or not
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
1. Go to the webui, where you will initialize the app
1. Restart the addon, to apply any option that should be applied

[repository]: https://github.com/alexbelgium/hassio-addons
