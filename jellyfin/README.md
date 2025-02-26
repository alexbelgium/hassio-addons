## &#9888; Open Issue : [🐛 [Jellyfin] File Not Found Errors (opened 2025-02-22)](https://github.com/alexbelgium/hassio-addons/issues/1784) by [@Tntdruid](https://github.com/Tntdruid)
# Home assistant add-on: jellyfin

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fjellyfin%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fjellyfin%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fjellyfin%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/jellyfin/stats.png)

## About

[jellyfin](https://jellyfin.org/) organizes video, music, live TV, and photos from personal media libraries and streams them to smart TVs, streaming boxes and mobile devices. This container is packaged as a standalone jellyfin Media Server.

This addon is based on the [docker image](https://github.com/linuxserver/docker-jellyfin) from linuxserver.io.

## Configuration

### Addon config

Webui can be found at `<your-ip>:8096`.

```yaml
PGID: user
GPID: user
TZ: timezone
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. ex. sda1, sdb1, MYNAS...
networkdisks: "//SERVER/SHARE" # optional, list of smb servers to mount, separated by commas
cifsusername: "username" # optional, smb username, same for all smb shares
cifspassword: "password" # optional, smb password
cifsdomain: "domain" # optional, allow setting the domain for the smb share
DOCKER_MODS: linuxserver/mods:jellyfin-opencl-intel|linuxserver/mods:jellyfin-amd|linuxserver/mods:jellyfin-rffmpeg # Install graphic drivers
```

### Enable ssl
#### Creating the PFX certificate file first
1. This part assumes you already have SSL certs in PEM format using the Let's Encrypt add on
2. Run this command `openssl pkcs12 -export -in fullchain.pem -inkey private_key.pem -passout pass: -out server.pfx`
3. Set the permission using `chmod 0700 server.pfx`
> Note:
> The above command creates a PFX file without a password, you can fill in a password with `-passout pass:"your-password"`
> but will also have to provide `your-password` to Jellyfin's configuration

#### Automating the PFX certificate

#### Jellyfin configuration
1. From the sidebar, click on `Administration` -> `Dashboard`
2. Under `Networking`, `Server Address Settings`, tick `Enable HTTPS`
3. Under `HTTPS Settings`, tick `Require HTTPS`
4. For `Custom SSL certificate path:`, point it to your PFX file and fill in the `Certificate password` if required
5. Scroll to the bottom and `Save`

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

[repository]: https://github.com/alexbelgium/hassio-addons
