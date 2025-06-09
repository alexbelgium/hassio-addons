# Home assistant add-on: Photoprism

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fphotoprism%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fphotoprism%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fphotoprism%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

MINIMUM CONFIG REQUIRED : 2 cores and 4 GB of memory

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/photoprism/stats.png)

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

Default user : admin
Default password : please_change_password

To access webdav, use as url : http://local-ip:addon-port/api/hassio.../originals
The second part (/api.../originals) Is described in the log when starting the addons

Options can be configured through two ways :

- Addon options

```yaml
ssl: true/false
certfile: fullchain.pem #ssl certificate, must be located in /ssl
keyfile: privkey.pem #sslkeyfile, must be located in /ssl
DB_TYPE: "list(sqlite|mariadb_addon|external)" # Mariadb is automatically configured is the addon is installed, sqlite does not need configuration
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. ex. sda1, sdb1, MYNAS...
networkdisks: "//SERVER/SHARE" # optional, list of smb servers to mount, separated by commas
cifsusername: "username" # optional, smb username, same for all smb shares
cifspassword: "password" # optional, smb password
cifsdomain: "domain" # optional, allow setting the domain for the smb share
ingress_disable: false # optional, if true disable ingress and simplifies the url to access with IP:port
UPLOAD_NSFW: "true" allow uploads that may be offensive
STORAGE_PATH: "/share/photoprism/storage" # storage PATH for cache, database and sidecar files
ORIGINALS_PATH: "/share/photoprism/originals" # originals PATH containing your photo and video collection
IMPORT_PATH: "/share/photoprism/import" # PATH for importing files to originals
BACKUP_PATH: "/share/photoprism/backup" # backup storage PATH
CONFIG_LOCATION: "/config/addons_config/config.yaml" # Sets the location of the config.yaml (see below)
```

- Config.yaml

Configuration is done by customizing the config.yaml that can be found in /config/addons_config/config.yaml

The complete list of options can be seen here : https://github.com/photoprism/photoprism/blob/develop/docker-compose.yml

- External db setting (@wesleygas)

Allow for the use of an external database. This can be done in photoprism by correctly setting the following options on the addons_config/photoprism/config.yaml file:

```yaml
PHOTOPRISM_DATABASE_DRIVER: "mysql"
PHOTOPRISM_DATABASE_SERVER: "IP:PORT"
PHOTOPRISM_DATABASE_NAME: "photoprism"
PHOTOPRISM_DATABASE_USER: "USERNAME"
PHOTOPRISM_DATABASE_PASSWORD: "PASSWORD
```

## Using Photoprism Command-Line Interface

Photoprism also provides a command line interface:

https://docs.photoprism.app/getting-started/docker-compose/#command-line-interface

You can access it via portainer addon or executing `docker exec -it <photoprism container id> bash` via _ssh_.

:warning: Do not use `docker exec <photoprism container id> photoprism` as this will lead to unpredictable behavior.

## Illustration

![1622396210_840_560](https://user-images.githubusercontent.com/44178713/127819841-2281ac79-ea96-4b41-9704-522957c5b9c3.jpg)

## Support

Create an issue on github

[repository]: https://github.com/alexbelgium/hassio-addons
