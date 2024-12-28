## &#9888; Open Issue : [🐛 [Inadyn] Custom provider ignores ssl variables (opened 2024-12-27)](https://github.com/alexbelgium/hassio-addons/issues/1684) by [@luisbandalap](https://github.com/luisbandalap)
# Home assistant add-on: Inadyn

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Finadyn%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Finadyn%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Finadyn%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/inadyn/stats.png)

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

```json
{
  "verify_address": false,
  "fake_address": false,
  "allow_ipv6": true,
  "iface": "eth0",
  "iterations": 0,
  "period": 300,
  "forced_update": 300,
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

```json
{
    {
      "provider": "duckdns",
      "username": "your-token",
      "hostname": "sub.duckdns.org"
    }
}
```

or:

```json
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

```json
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

### Multiple subdomains with same provider

Related to https://github.com/troglobit/inadyn#example

If you want use this add-on with several subdomains with the same provider, you have to enumerate domains like:

```json
{
  "providers": [
    {
      "hostname": "first.mydomain.dev",
      "provider": "domains.google.com:1",
      "username": "xxxxxxxxxxxxxxxx",
      "password": "xxxxxxxxxxxxxxxx"
    },
    {
      "hostname": "second.mydomain.dev",
      "provider": "domains.google.com:2",
      "username": "xxxxxxxxxxxxxxxx",
      "password": "xxxxxxxxxxxxxxxx"
    },
    {
      "hostname": "another.mydomain.dev",
      "provider": "domains.google.com:3",
      "username": "xxxxxxxxxxxxxxxx",
      "password": "xxxxxxxxxxxxxxxx"
    }
  ]
}
```

[repository]: https://github.com/alexbelgium/hassio-addons
