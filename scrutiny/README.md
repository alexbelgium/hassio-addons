# Home assistant add-on: Scrunity

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

## About

Scrutiny WebUI for smartd S.M.A.R.T monitoring
This addon is based on the [docker image](https://hub.docker.com/r/linuxserver/scrutiny) from linuxserver.io.

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

Due to a bug, the UI doesn't show on screen less than 960px. You need to switch your mobile browser to desktop mode for the UI to show. Here is the upstream bug opened : https://github.com/AnalogJ/scrutiny/issues/92

Webui can be found at <http://your-ip:8085>. Configurations can be done through the app, except for the following options.

```yaml
GUID: user
GPID: user
```

[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[privileged-shield]: https://img.shields.io/badge/privileged-required-orange.svg
