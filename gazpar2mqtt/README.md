# Home assistant add-on: gazpar2mqtt

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Supports
 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armv7 Architecture][armv7-shield]

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

Python script to fetch GRDF data and publish data to a mqtt broker.
See its github for all informations : https://github.com/yukulehe/gazpar2mqtt

## Configuration

Options can be configured through two ways :

- Addon options

```yaml
CONFIG_LOCATION: /config/gazpar2mqtt/config.yaml # Sets the location of the config.yaml (see below)
mqtt_autodiscover: true # Shows in the log the detail of the mqtt local server (if available). It can then be added to the config.yaml file.
TZ: Europe/Paris # Sets a specific timezone
```

- Config.yaml

Configuration is done by customizing the config.yaml that can be found in /config/gazpar2mqtt/config.yaml

The complete list of options can be seen here : https://github.com/yukulehe/gazpar2mqtt

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

[smb-shield]: https://img.shields.io/badge/SMB--green?style=plastic.svg
[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
