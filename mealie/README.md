# Hass.io Add-ons: Mealie
![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

## About
Mealie is a self hosted recipe manager and meal planner with a RestAPI backend and a reactive frontend application built in Vue for a pleasant user experience for the whole family.
This addon is based on the [docker image](https://hub.docker.com/r/hkotel/mealie) from hay-kot.

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

- Start the addon. Wait a while and check the log for any errors.
- Open yourdomain.com:9925 (where ":9925" is the port configured in the addon).
- Default 
  - Username: changeme@email.com
  - Password: MyPassword

## Support

If you have in issue with your installation, please be sure to checkout github.

[repository]: https://github.com/alexbelgium/hassio-addons
[smb-shield]: https://img.shields.io/badge/smb-yes-green.svg
[openvpn-shield]: https://img.shields.io/badge/openvpn-yes-green.svg
[ingress-shield]: https://img.shields.io/badge/ingress-yes-green.svg
[ssl-shield]: https://img.shields.io/badge/ssl-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
