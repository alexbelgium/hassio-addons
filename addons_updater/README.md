# Home assistant add-on: addons updater
![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

## About

This script allows to automatically update addons based on upstream new releases

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
gituser: your github username
gituser: your github email
gitpass: add your github password here, or a specific key if you have two factor identification enabled
```


[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
