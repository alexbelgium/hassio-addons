# Home assistant add-on: Immich CUDA

⚠️ The project is under very active development. Expect bugs and changes. Do not use it as the only way to store your photos and videos! (from the developer)

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fimmich_cuda%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fimmich_cuda%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fimmich_cuda%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/immich_cuda/stats.png)

## About

Self-hosted photo and video backup solution directly from your mobile phone with CUDA hardware acceleration support. This is the CUDA-enabled variant of Immich that provides hardware acceleration for machine learning tasks using NVIDIA GPUs.

This addon is based on the [docker image](https://github.com/imagegenius/docker-immich) from imagegenius with CUDA support enabled for enhanced performance.

## Hardware Requirements

- **NVIDIA GPU**: Compatible NVIDIA graphics card with CUDA support
- **CUDA Drivers**: NVIDIA drivers must be properly installed on the host system
- **Architecture**: AMD64 only (CUDA support not available on ARM architectures)

## Configuration

Webui can be found at `<your-ip>:8080`. PostgreSQL can be either internal or external.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `data_location` | str | `/share/immich` | Path where Immich data is stored |
| `library_location` | str | | Path to photo/video library |
| `TZ` | str | | Timezone (e.g., `Europe/London`) |
| `localdisks` | str | | Local drives to mount (e.g., `sda1,sdb1,MYNAS`) |
| `networkdisks` | str | | SMB shares to mount (e.g., `//SERVER/SHARE`) |
| `cifsusername` | str | | SMB username for network shares |
| `cifspassword` | str | | SMB password for network shares |
| `cifsdomain` | str | | SMB domain for network shares |
| `DB_HOSTNAME` | str | `homeassistant.local` | Database hostname |
| `DB_USERNAME` | str | `postgres` | Database username |
| `DB_PASSWORD` | str | `homeassistant` | Database password |
| `DB_DATABASE_NAME` | str | `immich` | Database name |
| `DB_PORT` | int | `5432` | Database port |
| `DB_ROOT_PASSWORD` | str | | Database root password |
| `JWT_SECRET` | str | | JWT secret for authentication |
| `DISABLE_MACHINE_LEARNING` | bool | `false` | Disable ML features (not recommended for CUDA variant) |
| `MACHINE_LEARNING_WORKERS` | int | `1` | Number of ML workers (can be increased with CUDA) |
| `MACHINE_LEARNING_WORKER_TIMEOUT` | int | `120` | ML worker timeout (seconds) |
| `skip_permissions_check` | bool | `false` | Skip file permissions checking |

### Example Configuration

```yaml
data_location: "/share/immich"
library_location: "/media/photos"
TZ: "Europe/London"
localdisks: "sda1,sdb1"
networkdisks: "//192.168.1.100/photos"
cifsusername: "photouser"
cifspassword: "password123"
DB_HOSTNAME: "core-mariadb"
DB_USERNAME: "immich"
DB_PASSWORD: "secure_password"
DB_DATABASE_NAME: "immich"
JWT_SECRET: "your-secret-key-here"
DISABLE_MACHINE_LEARNING: false
MACHINE_LEARNING_WORKERS: 2
MACHINE_LEARNING_WORKER_TIMEOUT: 180
```

### Mounting Drives

This addon supports mounting both local drives and remote SMB shares:

- **Local drives**: See [Mounting Local Drives in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-Local-Drives-in-Addons)
- **Remote shares**: See [Mounting Remote Shares in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-remote-shares-in-Addons)

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

**Prerequisites:**
- NVIDIA GPU with CUDA support
- NVIDIA drivers installed on the host system
- AMD64 architecture (ARM not supported)

**Steps:**
1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

**Database Setup:**
Beware that you need to install a separate postgres addon to be able to connect the database. You can install the postgres addon already in my repository.
Beware to change the password BEFORE starting it ; it won't change afterwards

## Support

Create an issue on github, or ask on the [home assistant thread](https://community.home-assistant.io/t/home-assistant-addon-immich/282108/3)

[repository]: https://github.com/alexbelgium/hassio-addons
