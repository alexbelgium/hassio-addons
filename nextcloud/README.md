## &#9888; Open Request : [✨ [REQUEST] immich and Nextcloud Ingress support (opened 2025-03-15)](https://github.com/alexbelgium/hassio-addons/issues/1812) by [@bessertristan09](https://github.com/bessertristan09)
# Home assistant add-on: Nextcloud

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnextcloud%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnextcloud%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnextcloud%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

![Uses elasticsearch][elasticsearch-shield]

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/nextcloud/stats.png)

## About

Various tweaks and configuration options addition.
Inital fork from version : https://github.com/haberda/hassio_addons
This addon is based on the [docker image](https://github.com/linuxserver/docker-nextcloud) from linuxserver.io.

## Configuration

Webui can be found at `<your-ip>:port`.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `PGID` | int | `1000` | Group ID for file permissions |
| `PUID` | int | `1000` | User ID for file permissions |
| `TZ` | str | | Timezone (e.g., `Europe/London`) |
| `additional_apps` | str | | Additional APK packages to install (comma-separated) |
| `trusted_domains` | str | | Trusted domains for Nextcloud access |
| `use_own_certs` | bool | `false` | Use custom SSL certificates |
| `certfile` | str | `fullchain.pem` | SSL certificate file (in `/ssl/`) |
| `keyfile` | str | `privkey.pem` | SSL private key file (in `/ssl/`) |
| `OCR` | bool | `false` | Enable Tesseract OCR capability |
| `OCRLANG` | str | | OCR languages (e.g., `fra,eng`) |
| `Full_Text_Search` | bool | `false` | Enable full-text search with Elasticsearch |
| `elasticsearch_server` | str | | Elasticsearch server address (ip:port) |
| `enable_thumbnails` | bool | `true` | Enable thumbnail generation |
| `default_phone_region` | str | | Default phone region (ISO 3166-1 alpha-2) |
| `disable_updates` | bool | `false` | Prevent automatic app updates |
| `env_memory_limit` | str | `512M` | PHP memory limit |
| `env_post_max_size` | str | `512M` | Maximum POST size |
| `env_upload_max_filesize` | str | `512M` | Maximum upload file size |
| `localdisks` | str | | Local drives to mount (e.g., `sda1,sdb1,MYNAS`) |
| `networkdisks` | str | | SMB shares to mount (e.g., `//SERVER/SHARE`) |
| `cifsusername` | str | | SMB username for network shares |
| `cifspassword` | str | | SMB password for network shares |
| `cifsdomain` | str | | SMB domain for network shares |
| `skip_permissions_check` | bool | `false` | Skip file permissions checking |

### Example Configuration

```yaml
PGID: 1000
PUID: 1000
TZ: "Europe/London"
additional_apps: "vim,curl"
trusted_domains: "nextcloud.example.com,192.168.1.100"
use_own_certs: true
certfile: "fullchain.pem"
keyfile: "privkey.pem"
OCR: true
OCRLANG: "eng,fra,deu"
enable_thumbnails: true
env_memory_limit: "1024M"
localdisks: "sda1,sdb1"
networkdisks: "//192.168.1.100/nextcloud"
cifsusername: "nextcloud_user"
cifspassword: "password123"
```

### Mounting Drives

This addon supports mounting both local drives and remote SMB shares:

- **Local drives**: See [Mounting Local Drives in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-Local-Drives-in-Addons)
- **Remote shares**: See [Mounting Remote Shares in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-remote-shares-in-Addons)

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

### Custom Script Example

Create `/config/addons_autoscripts/nextcloud-ocr.sh` for custom initialization:

```bash
#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# Custom script executed at addon start
# Runs only after initialization is done

mkdir -p /scripts
if [ ! -f /app/www/public/occ ]; then
    cp /config/addons_autoscripts/"$(basename "${BASH_SOURCE}")" /scripts/ && exit 0
fi

echo "Scanning files"
sudo -u abc php /app/www/public/occ files:scan --all
echo "File scan completed!"
```

### Change the temp folder to avoid bloating emmc on HA systems (thanks @senna1992)

See ; https://github.com/alexbelgium/hassio-addons/discussions/1370

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
continu