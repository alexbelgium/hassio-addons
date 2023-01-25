## &#9888; Open Request : [✨ [REQUEST] Nextcloud - Enable antivirus (opened 2023-01-25)](https://github.com/alexbelgium/hassio-addons/issues/669) by [@amaciuc](https://github.com/amaciuc)
# Home assistant add-on: Nextcloud

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnextcloud%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnextcloud%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnextcloud%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://github.com/alexbelgium/hassio-addons/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Builder](https://github.com/alexbelgium/hassio-addons/workflows/Builder/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Uses elasticsearch][elasticsearch-shield]

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_


[![Stargazers repo roster for @alexbelgium/hassio-addons](https://git-lister.onrender.com/api/stars/alexbelgium/hassio-addons?limit=30)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

Various tweaks and configuration options addition.
Inital fork from version : https://github.com/haberda/hassio_addons
This addon is based on the [docker image](https://github.com/linuxserver/docker-nextcloud) from linuxserver.io.

## Configuration


### Custom scripts

Scripts with .sh ending located in /config/addons_config/nextcloud will be executed at boot


### Addon options

```yaml
additional_apps: vim,nextcloud #specify additional apk files to install ; separated by commas
PGID/PUID: 1000 #allows setting user.
trusted_domains: your-domain.com #allows to select the trusted domains. Domains not in this lis will be removed, except for the first one used in the initial configuration.
OCR: false #set to true to install tesseract-ocr capability.
OCRLANG: fra,eng #Any language can be set from this page (always three letters) [here](https://tesseract-ocr.github.io/tessdoc/Data-Files#data-files-for-version-400-november-29-2016).
data_directory: path for the main data directory. Defaults to `/share/nextcloud`.
use_own_certs: true/false #if true, use the certfile and keyfile specified
certfile: fullchain.pem #ssl certificate, must be located in /ssl
keyfile: privkey.pem #sslkeyfile, must be located in /ssl
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. Ex: sda1, sdb1, MYNAS...
networkdisks: "//SERVER/SHARE" # optional, list of smbv2/3 servers to mount, separated by commas
cifsusername: "username" # optional, smb username, same for all smb shares
cifspassword: "password" # optional, smb password, same for all smb shares)
```

Webui can be found at `<your-ip>:port`.


### Use mariadb as the main database (Thanks @amaciuc)

If you notice the following warning at your first `webui` running:
```bash
Performance warning
You chose SQLite as database.
SQLite should only be used for minimal and development instances. For production we recommend a different database backend.
If you use clients for file syncing, the use of SQLite is highly discouraged.
```
and you want to overcome this, follow the below steps:

- 1. Install `mariadb` add-on, configure it with some random infos and start it. It is important to start it successfully in order to be seen by `nextcloud` in the network.
- 2. Install `nextcloud` add-on (or restart it if you have already installed), watch the logs until you will notice the following `warning`:
  ```bash
  WARNING: MariaDB addon was found! It can't be configured automatically due to the way Nextcloud works, but you can configure it manually when running the web UI for the first time using those values :
  Database user : service
  Database password : Eangohyuchae6aif7saich2nies8xaivaejaNgaev6gi3yohy8ha2aexaetei6oh
  Database name : nextcloud
  Host-name : core-mariadb:3306
  ```

- 3. Go back at `mariadb` add-on, configure it with above credentials and restart it. Make sure the add-on is creating the `netxcloud` database.
- 4. Go in the webui and fill all required info. Here you can view an example:

![image](https://user-images.githubusercontent.com/19391765/207888717-50b43002-a5e2-4782-b5c9-1f582309df2b.png)

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Go to the webui, where you will create your username, password, and database (if using mariadb, infos are in the log)
1. Restart the addon, to apply any option that should be applied

## HA integration

See this component : https://www.home-assistant.io/integrations/nextcloud/

[repository]: https://github.com/alexbelgium/hassio-addons
[elasticsearch-shield]: https://img.shields.io/badge/Elasticsearch-optional-blue.svg?logo=elasticsearch
