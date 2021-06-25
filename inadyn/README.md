# Home assistant add-on: Inadyn

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

## About

[Inadyn](https://github.com/troglobit/inadyn), or In-a-Dyn, is a small and simple Dynamic DNS, DDNS, client with HTTPS support. Commonly available in many GNU/Linux distributions, used in off the shelf routers and Internet gateways to automate the task of keeping your Internet name in sync with your public¹ IP address. It can also be used in installations with redundant (backup) connections to the Internet.
Based on https://hub.docker.com/r/troglobit/inadyn
Project house : https://github.com/troglobit/inadyn
Some code borrowed from https://github.com/nalipaz/hassio-addons

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

To configure with addon options, no webUI.
For configuration, see https://github.com/troglobit/inadyn

```
"verify_address": "bool?",
"fake_address": "bool?",
"allow_ipv6": "bool?",
"iface": "str?",
"iterations": "int?",
"period": "int?",
"forced_update": "bool?",
"secure_ssl": "bool?",
"providers":
      - "provider": "str",
        "custom_provider": "bool?",
        "username": "str",
        "password": "str?",
        "ssl": "bool?",
        "hostname": "str",
        "checkip_ssl": "bool?",
        "checkip_server": "str?",
        "checkip_command": "str?",
        "checkip_path": "str?",
        "user_agent": "str?",
        "wildcard": "bool?",
        "ddns_server": "str?",
        "ddns_path": "str?",
        "append_myip": "bool?"
```

[smb-shield]: https://img.shields.io/badge/SMB--green?style=plastic.svg
[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
