# Home assistant add-on: Piwigo

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

## About

Piwigo is a photo gallery software for the Web.
This addon is based on the [docker image](https://github.com/linuxserver/piwigo) from linuxserver.io.

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

1. You must create a user and database for piwigo to use in a mysql/mariadb server.
1. In the setup page for database, use the ip address rather than hostname.
1. A basic nginx configuration file can be found in /config/piwigo/nginx/site-confs, edit the file to enable ssl (port 443 by default), set servername etc.
1. Self-signed keys are generated the first time you run the container and can be found in /data/keys, if needed, you can replace them with your own.
1. The easiest way to edit the configuration file is to go in /config/piwigo from home assistant local files editor to configure email settings etc.

Webui can be found at <http://your-ip:81>.

```yaml
GUID: user
GPID: user
localdisks: "sda1" # list of device to mount (optional)
networkdisks: "<//SERVER/SHARE>" # list of smbv2/3 servers to mount (optional)
cifsusername: "username" # smb username (optional)
cifspassword: "password" # smb password (optional)
```

[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
