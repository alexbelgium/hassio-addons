# Home assistant add-on: Organizr

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Supports
 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armv7 Architecture][armv7-shield]

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

An HTPC/Homelab services organizer that is written in PHP.
This addon is based on the [docker image](https://hub.docker.com/r/organizr/organizr) from linuxserver.io.

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

Webui can be found at <http://your-ip:80>.
Create the db in /data/...

```yaml
GUID: user, can't be 0
GPID: user, can't be 0
```

## Support

Create an issue on github

## Illustration

![bjaSt3fTfdXhw5vyl-7Lqz1EOjJIyh8lrdqxA53qO6E](https://user-images.githubusercontent.com/44178713/123061812-43601b00-d40c-11eb-993c-2aed31072775.jpg)

[repository]: https://github.com/alexbelgium/hassio-addons
[smb-shield]: https://img.shields.io/badge/smb-yes-green.svg
[openvpn-shield]: https://img.shields.io/badge/openvpn-yes-green.svg
[ingress-shield]: https://img.shields.io/badge/ingress-yes-green.svg
[ssl-shield]: https://img.shields.io/badge/ssl-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
