# Home assistant add-on: Arpspoof

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Supports 
 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]
![Supports smb mounts][smb-shield]

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

You can use a `command_line` switch to temporary disable a internet device in your network.


```yaml
- platform: command_line
  switches:
    iphone_internet:
      friendly_name: "iPhone internet"
      command_off: "/usr/bin/curl -X GET http://{HA-IP}:7022/disconnect?ip={iPhoneIP}"
      command_on: "/usr/bin/curl -X GET http://{HA-IP}:7022/reconnect?ip={iPhoneIP}"
      command_state: "/usr/bin/curl -X GET http://{HA-IP}:7022/status?ip={iPhoneIP}"
      value_template: >
        {{ value != "1" }}
```

## Support

Create an issue on github

## Illustration

NO illustration

[repository]: https://github.com/alexbelgium/hassio-addons
[smb-shield]: https://img.shields.io/badge/smb-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
