# Home assistant add-on: addons updater

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faddons_updater%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faddons_updater%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faddons_updater%2Fconfig.json)
![Webui](https://img.shields.io/badge/dynamic/json?color=success&label=WebUI&query=%24.webui&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faddons_updater%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://github.com/alexbelgium/hassio-addons/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Builder](https://github.com/alexbelgium/hassio-addons/workflows/Builder/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

This script allows to automatically update addons based on upstream new releases. This is only an helper tool for developers. End users don’t need that to update their addons - they are automatically alerted by HA when an update is available

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Make sure that the two ports are open on your router
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

## Configuration

No webUI. Set everything through configuration.

```yaml
addon:
  - slug: the slug name from your repo
    beta: true/false ; should it look only for releases or prereleases ok
    fulltag: true is for example "v3.0.1-ls67" false is "3.0.1"
    repository: 'name/repo' coming from github
    upstream: name/repo, example is 'linuxserver/docker-emby'
    source: github or dockerhub
    filter: filter a text in the release name
gituser: your github username
gitpass: your github password
gitmail: your github email
verbose: 'false'
gitapi: optional, it is the API key from your github repo
```

Example:

```yaml
addon:
  - slug: sonarr
    beta: false
    fulltag: false
    repository: alexbelgium/hassio-addons
    upstream: linuxserver/docker-sonarr
  - slug: transmission
    beta: false
    fulltag: true
    repository: alexbelgium/hassio-addons
    upstream: linuxserver/docker-transmission
  - slug: ubooquity
    beta: false
    fulltag: false
    repository: alexbelgium/hassio-addons
    upstream: linuxserver/docker-ubooquity
gituser: your github username
gitpass: your github password
gitmail: your github email
verbose: "false"
```

[repository]: https://github.com/alexbelgium/hassio-addons
