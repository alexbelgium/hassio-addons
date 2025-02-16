## &#9888; Open Issue : [🐛 [BirdNET-Pi] timezone (opened 2024-12-10)](https://github.com/alexbelgium/hassio-addons/issues/1664) by [@alexbelgium](https://github.com/alexbelgium)
## &#9888; Open Issue : [🐛 [Birdnet-Pi] Docker Container (opened 2025-02-13)](https://github.com/alexbelgium/hassio-addons/issues/1766) by [@alexbelgium](https://github.com/alexbelgium)
# Home assistant add-on: birdnet-pi

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbirdnet-pi%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbirdnet-pi%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbirdnet-pi%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/birdnet-pi/stats.png)

## About

---

[birdnet-pi](https://github.com/Nachtzuster/BirdNET-Pi) is an AI solution for continuous avian monitoring and identification originally developed by @mcguirepr89 on github (https://github.com/mcguirepr89/BirdNET-Pi), whose work is continued by @Nachtzuster and other developers on an active fork (https://github.com/Nachtzuster/BirdNET-Pi)

Features of the addon :
- Robust base image provided by [linuxserver](https://github.com/linuxserver/docker-baseimage-debian)
- Working docker system thanks to https://github.com/gdraheim/docker-systemctl-replacement
- Uses HA pulseaudio server
- Uses HA tmpfs to store temporary files in ram and avoid disk wear
- Exposes all config files to /config to allow remanence and easy access
- Allows to modify the location of the stored bird songs (preferably to an external hdd)
- Supports ingress, to allow secure remote access without exposing ports

## Configuration

---

Install, then start the addon a first time
Webui can be found by two ways :
- Ingress from HA (no password but some functions don't work)
- Direct access with <http://homeassistant:port>, port being the one defined in the birdnet.conf. The username when asked for a password is `birdnet`, the password is the one that you can define in the birdnet.con (blank by default). This is different than the password from the addon options, which is the one that must be used to access the web terminal

Web terminal access : uesrname `pi`, password : as defined in the addon options

You'll need a microphone : either use one connected to HA or the audio stream of a rstp camera.

Options can be configured through three ways :

- Addon options

```yaml
BIRDSONGS_FOLDER: folder to store birdsongs file # It should be an ssd if you want to avoid clogging of analysis
MQTT_DISABLED : if true, disables automatic mqtt publishing. Only valid if there is a local broker already available
LIVESTREAM_BOOT_ENABLED: start livestream from boot, or from settings
PROCESSED_FOLDER_ENABLED : if enabled, you need to set in the birdnet.conf (or the setting of birdnet) the number of last wav files that will be saved in the temporary folder "/tmp/Processed" within the tmpfs (so no disk wear) in case you want to retrieve them. This amount can be adapted from the addon options
TZ: Etc/UTC specify a timezone to use, see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
pi_password: set the user password to access the web terminal
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. ex. sda1, sdb1, MYNAS...
networkdisks: "//SERVER/SHARE" # optional, list of smb servers to mount, separated by commas
cifsusername: "username" # optional, smb username, same for all smb shares
cifspassword: "password" # optional, smb password
cifsdomain: "domain" # optional, allow setting the domain for the smb share
```

- Config.yaml
Additional variables can be configured using the config.yaml file found in /config/db21ed7f_birdnet-pi/config.yaml using the Filebrowser addon

- Config_env.yaml
Additional environment variables can be configured there

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

## Integration with HA

---
### Apprise

You can use apprise to send notifications with mqtt, then act on those using HomeAssistant
Further informations : https://wander.ingstar.com/projects/birdnetpi.html

### Automatic mqtt

If mqtt is installed, the addon automatically updates the birdnet topic with each detected species

## Using ssl

---

Option 1 : Install let's encrypt addon, generate certificates. They are by default certfile.pem and keyfile.pem stored in /ssl. Just enable ssl from the addon option and it will work.

Option 2 : enable port 80, define your BirdNET-Pi URL as https. Certificate will be automatically generated by caddy

## Improve detections

---

### Gain for card

Using alsamixer in the Terminal tab, make sure that the sound level is high enough but not too high (not in the red part)
https://github.com/mcguirepr89/BirdNET-Pi/wiki/Adjusting-your-sound-card

### Ferrite

Adding ferrite beads lead in my case to worst noise

### Aux to usb adapters

Based on my test, only adapters using KT0210 (such as Ugreen's) work. I couldn't get adapters based on ALC to be detected.

### Microphone comparison

Recommended microphones ([full discussion here](https://github.com/mcguirepr89/BirdNET-Pi/discussions/39)):
- Clippy EM272 (https://www.veldshop.nl/en/smart-clippy-em272z1-mono-omni-microphone.html) + ugreen aux to usb connector : best sensitivity with lavalier tech
- Boya By-LM40 : best quality/price
- Hyperx Quadcast : best sensitivity with cardioid tech

Conclusion, using mic from Dahua is good enough, EM272 is optimal, but Boya by-lm40 is a very good compromise as birndet model analysis the 0-15000Hz range

![image](https://github.com/alexbelgium/hassio-addons/assets/44178713/df992b79-7171-4f73-b0c0-55eb4256cd5b)

### Denoise ([Full discussion here](https://github.com/mcguirepr89/BirdNET-Pi/discussions/597))

Denoise is frowned upon by serious researchers. However it does seem to significantly increase quality of detection ! Here is how to do it in HA :
- Using Portainer addon, go in the hassio_audio container, and modify the file /etc/pulse/system.pa to add the line `load-module module-echo-cancel`
- Go in the Terminal addon, and type `ha audio restart`
- Select the echo cancelled device as input device in the addon options

### High pass

Should be avoided as the model uses the whole 0-15khz range

## Common issues

Not yet available

## Support

Create an issue on github

---

![illustration](https://raw.githubusercontent.com/tphakala/birdnet-pi/main/doc/birdnet-pi-dashboard.webp)
