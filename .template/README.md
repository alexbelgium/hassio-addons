# Home assistant add-on: qBittorrent
![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

## About

Transmission is a bittorrent client.
This addon is based on the [docker image](https://github.com/linuxserver/qbittorrent) from linuxserver.io.

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
**Webui**

- Webui: http://your-ip:8081
- Default username/password : described in the startup log.

**Options**
```yaml
GUID: user
GPID: user
ssl: true/false
certfile: fullchain.pem #ssl certificate
keyfile: privkey.pem #sslkeyfile
localdisks: "sda1" # list of device to mount
networkdisks: "<//SERVER/SHARE>" # list of smbv2/3 servers to mount
cifsusername: "username" # smb username
cifspassword: "password" # smb password
```
[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
