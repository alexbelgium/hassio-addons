# Home assistant add-on: Photoprism

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Supports
 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armv7 Architecture][armv7-shield]

MINIMUM CONFIG REQUIRED : 2 cores and 4 GB of memory

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

A server-based application for browsing, organizing and sharing your personal photo collection.

Project homepage : https://github.com/photoprism/photoprism

Based on the docker image : https://hub.docker.com/r/photoprism/photoprism

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

Webui can be found at <http://your-ip:2342>

```yaml
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. Ex: sda1, sdb1, MYNAS...
networkdisks: "//SERVER/SHARE" # optional, list of smb servers to mount, separated by commas
cifsusername: "username" # optional, smb username, same for all smb shares
cifspassword: "password" # optional, smb password
cifsdomain: "domain" # optional, allow setting the domain for the smb share
UPLOAD_NSFW: "true" allow uploads that may be offensive
STORAGE_PATH: "/share/photoprism/storage" # storage PATH for cache, database and sidecar files
ORIGINALS_PATH: "/share/photoprism/originals" # originals PATH containing your photo and video collection
IMPORT_PATH: "/share/photoprism/import" # PATH for importing files to originals
BACKUP_PATH: "/share/photoprism/backup" # backup storage PATH
CUSTOM_OPTIONS: "--site-title HA_Photoprism" # custom options from https://docs.photoprism.org/getting-started/config-options/
```

## Illustration

![1622396210_840_560](https://user-images.githubusercontent.com/44178713/127819841-2281ac79-ea96-4b41-9704-522957c5b9c3.jpg)

## Support

Create an issue on github

[repository]: https://github.com/alexbelgium/hassio-addons
[smb-shield]: https://img.shields.io/badge/smb-yes-green.svg
[openvpn-shield]: https://img.shields.io/badge/openvpn-yes-green.svg
[ingress-shield]: https://img.shields.io/badge/ingress-yes-green.svg
[ssl-shield]: https://img.shields.io/badge/ssl-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
