# Home assistant add-on: Inadyn

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Supports
 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armv7 Architecture][armv7-shield]

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

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

The available configuration options are as follows (this is filled in with some example data):

```
{
  "verify_address": false,
  "fake_address": false,
  "allow_ipv6": true,
  "iface": "eth0",
  "iterations": 0,
  "period": 300,
  "forced_update": false,
  "secure_ssl": true,
  "providers": [
    {
      "provider": "providerslug",
      "custom_provider": false,
      "username": "yourusername",
      "password": "yourpassword_or_token",
      "ssl": true,
      "hostname": "dynamic-subdomain.example.com",
      "checkip_ssl": false,
      "checkip_server": "api.example.com",
      "checkip_command": "/sbin/ifconfig eth0 | grep 'inet6 addr'",
      "checkip_path": "/",
      "user_agent": "Mozilla/5.0",
      "ddns_server": "ddns.example.com",
      "ddns_path": "",
      "append_myip": false
    }
  ]
}
```

You should not fill in all of these, only use what is necessary. A typical example would look like:

```
{
    {
      "provider": "duckdns",
      "username": "your-token",
      "hostname": "sub.duckdns.org"
    }
  ]
}
```

or:

```
{
  "providers": [
    {
      "provider": "someprovider",
      "username": "username",
      "password": "password",
      "hostname": "your.domain.com"
    }
  ]
}
```

for a custom provider that is not supported by inadyn you can do:

```
{
  "providers": [
    {
      "provider": "arbitraryname",
      "username": "username",
      "password": "password",
      "hostname": "your.domain.com",
      "ddns_server": "api.cp.easydns.com",
      "ddns_path": "/somescript.php?hostname=%h&myip=%i",
      "custom_provider": true
    }
  ]
}
```

the tokens in ddns_path are outlined in the `inadyn.conf(5)` man page.

[smb-shield]: https://img.shields.io/badge/SMB--green?style=plastic.svg
[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
