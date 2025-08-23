# Home assistant add-on: Codex

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcodex%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcodex%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcodex%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/codex/stats.png)

## About

---

[Codex](https://github.com/ajslater/codex) is a web based comic archive browser and reader
This addon is based on the official docker image : https://hub.docker.com/r/ajslater/codex

## Installation

---

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and adapt the software options

## Configuration

Webui can be found at <http://homeassistant:PORT>.
The default username/password : described in the startup log.
Configurations can be done through the app webUI, except for the following options

## Add theme/squeleton

You can place the user folder from the theme/skeleton in /share/codex/www/user,

## Options

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `PGID` | Group ID for file permissions | `0` | `1000` |
| `PUID` | User ID for file permissions | `0` | `1000` |
| `TZ` | Timezone in long format | - | `America/Los_Angeles` |
| `CODEX_RESET_ADMIN` | Reset admin user and password to defaults | - | `1` |
| `CODEX_SKIP_INTEGRITY_CHECK` | Skip database integrity repair on startup | - | `1` |
| `csrf_allowed` | Comma separated list of addresses allowed to access the app | `http://homeassistant.local:8123,https://homeassistant.local:8123` | `http://localhost:8123` |
| `localdisks` | Local drives to mount (e.g., `sda1,sdb1,MYNAS`) | - | `sda1,sdb1,MYNAS` |
| `networkdisks` | SMB shares to mount (e.g., `//SERVER/SHARE`) | - | `//SERVER/SHARE` |
| `cifsusername` | SMB username for network shares | - | `username` |
| `cifspassword` | SMB password for network shares | - | `password` |
| `cifsdomain` | SMB domain for network shares | - | `WORKGROUP` |

```yaml
PGID: 1000
PUID: 1000
TZ: "America/Los_Angeles"
CODEX_RESET_ADMIN: 1
CODEX_SKIP_INTEGRITY_CHECK: 1
csrf_allowed: "http://homeassistant.local:8123,https://homeassistant.local:8123"
localdisks: "sda1,sdb1"
networkdisks: "//SERVER/SHARE"
cifsusername: "username"
cifspassword: "password"
cifsdomain: "WORKGROUP"
```

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

### Mounting Drives

This addon supports mounting both local drives and remote SMB shares:

- **Local drives**: See [Mounting Local Drives in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-Local-Drives-in-Addons)
- **Remote shares**: See [Mounting Remote Shares in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-remote-shares-in-Addons)

## Illustration

![image](https://github.com/alexbelgium/hassio-addons/assets/44178713/f1cf3cad-5bda-46df-a0f5-864b127d7b6b)

## Support

Create an issue on github

[repository]: https://github.com/alexbelgium/hassio-addons
