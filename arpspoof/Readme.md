# Home assistant add-on: Arpspoof

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Farpspoof%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Farpspoof%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Farpspoof%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://github.com/alexbelgium/hassio-addons/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Builder](https://github.com/alexbelgium/hassio-addons/workflows/Builder/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/builder.yaml)

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

[arpspoof](https://github.com/t0mer/Arpspoof-Docker) adds ability to block internet connection for local network devices
This addon is based on the docker image https://hub.docker.com/r/techblog/arpspoof-docker

See all informations here : https://en.techblog.co.il/2021/03/15/home-assistant-cut-internet-connection-using-arpspoof/

## Installation

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

Webui can be found at <http://your-ip:PORT>.

```yaml
ROUTER_IP: 127.0.0.1 #Required Router IP
INTERFACE_NAME: name #Required Interface name. Autofilled if empty.
```

## Home-Assistant configuration

Description : [techblog](https://en.techblog.co.il/2021/03/15/home-assistant-cut-internet-connection-using-arpspoof/)

You can use a `command_line` switch to temporary disable a internet device in your network.

```yaml
- platform: command_line
  switches:
    iphone_internet:
      friendly_name: "iPhone internet"
      command_off: "/usr/bin/curl -f -X GET http://{HA-IP}:7022/disconnect?ip={iPhoneIP}"
      command_on: "/usr/bin/curl -f -X GET http://{HA-IP}:7022/reconnect?ip={iPhoneIP}"
      command_state: "/usr/bin/curl -f -X GET http://{HA-IP}:7022/status?ip={iPhoneIP}"
      value_template: >
        {{ value != "1" }}
```

## Support

Create an issue on github

## Illustration

No illustration
