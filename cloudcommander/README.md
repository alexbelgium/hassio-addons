# Home assistant add-on: Cloudcommander
[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=for-the-badge&logoColor=white

![Supports 
 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

## About

Cloud Commander a file manager for the web with console and editor.
This addon is based on the [docker image](https://hub.docker.com/r/coderaiser/cloudcmd).

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.

## Configuration

Webui can be found at `<your-ip>:8000`.

```yaml
"localdisks": "sda1" # Optional, requires priviledged mode
"networkdisks": "//SERVER/SHARE" # optional, list of smb servers to mount, separated by commas
"cifsusername": "username" # optional, smb username, same for all smb shares
"cifspassword": "password" # optional, smb password
"smbv1": "bool?" # smb v1
"DROPBOX_TOKEN": "str?" # see https://cloudcmd.io/
"CUSTOM_OPTIONS": "--name Homeassistant" # custom options from https://cloudcmd.io/
```

[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
