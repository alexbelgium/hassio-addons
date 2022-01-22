# Home assistant add-on: Joal

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Supports
 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armv7 Architecture][armv7-shield]

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

An open source command line RatioMaster with WebUI.
This addon is based on the [docker image](https://hub.docker.com/r/anthonyraymond/joal) from Anthony Raymond.
All credits for the app go to Anthony Raymond, please visit his repository here : https://github.com/anthonyraymond/joal

## Configuration

Joal configuration : in the addon log are all informations tailored for your system

Addon options

```yaml
secret_token: lrMY24Byhx #you can encode your own token here that will be used to identify in the app
ui_path: joal #the path where Joal will be accessible
run_duration: 12h #for how long should the addon run. Must be formatted as number + time unit (ex : 5s, or 2m, or 12h, or 5d...)
```

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Make sure that the two ports are open on your router
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

## Support

For HA : create an issue on github
For Joal : see the upstream repo here https://github.com/anthonyraymond/joal

## Illustration

![image](https://user-images.githubusercontent.com/44178713/117990142-29c3b200-b33d-11eb-86c8-a3007d73c3da.png)

[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
