![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

Hi, I've create an addon for my use and wanted to share it if it can be useful to other people ;-)


# About
----------
[Scrutiny](https://github.com/AnalogJ/scrutiny) is a Hard Drive Health Dashboard & Monitoring solution, merging manufacturer provided S.M.A.R.T metrics with real-world failure rates. This addon is based on the [docker image](https://hub.docker.com/r/linuxserver/scrutiny) from [linuxserver.io](https://www.linuxserver.io/).

Features :
- SMART monitoring
- Automatic addition of local drives
- Hourly updates
- Ingress with/without ssl
- Automatic upstream updates

# Installation
----------
The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. [Add my Hass.io add-ons repository][repository] to your home assistant instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI (Ingress based) and adapt the software options

# Configuration
--------------
Webui can be found at <http://your-ip:8080>, or through Ingress. 
It automatically mounts all local drives.

```yaml
GUID: user
GPID: user
ssl: true/false (for Ingress)
certfile: fullchain.pem #ssl certificate
keyfile: privkey.pem #sslkeyfile
```
# Illustration
--------------
![](https://github.com/AnalogJ/scrutiny/raw/master/docs/dashboard.png)

## Support
Create an issue on github, or ask on the [home assistant thread](https://community.home-assistant.io/t/home-assistant-addon-scrutiny-smart-dashboard/295747)

https://github.com/alexbelgium/hassio-addons

[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
