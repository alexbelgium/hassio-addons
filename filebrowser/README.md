## &#9888; Open Issue : [🐛 [Filebrowser] Crashing on new install (opened 2025-08-02)](https://github.com/alexbelgium/hassio-addons/issues/1993) by [@LivArt01](https://github.com/LivArt01)
# Home assistant add-on: Filebrowser

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffilebrowser%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffilebrowser%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffilebrowser%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/filebrowser/stats.png)

## About

Web-based file management interface that provides a secure way to browse, upload, download, edit and manage files on your Home Assistant system. Filebrowser offers a clean, modern interface for handling your files through a web browser, with support for multiple file formats, preview capabilities, and comprehensive file operations.

This addon is based on the [docker image](https://hub.docker.com/r/filebrowser/filebrowser) from the official Filebrowser project.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Home Assistant add-on.

1. [Add my Home Assistant add-ons repository][repository] to your Home Assistant instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Access the web UI through the sidebar or at `<your-ip>:8071`.

## Configuration

The web UI can be found at `<your-ip>:8071` or through the Home Assistant sidebar when using Ingress.

**Default credentials:**
- Username: `admin`
- Password: `admin`

**Important:** Change the default credentials immediately after first login for security.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ssl` | bool | `false` | Enable HTTPS for web interface |
| `certfile` | str | `fullchain.pem` | SSL certificate file (in `/ssl/`) |
| `keyfile` | str | `privkey.pem` | SSL private key file (in `/ssl/`) |
| `NoAuth` | bool | `true` | Disable authentication (resets database when changed) |
| `disable_thumbnails` | bool | `true` | Disable thumbnail generation for improved performance |
| `base_folder` | str | _(optional)_ | Root folder for file browser (defaults to all mapped folders) |
| `localdisks` | str | _(optional)_ | Local drives to mount (e.g., `sda1,sdb1,MYNAS`) |
| `networkdisks` | str | _(optional)_ | SMB shares to mount (e.g., `//SERVER/SHARE`) |
| `cifsusername` | str | _(optional)_ | SMB username for network shares |
| `cifspassword` | str | _(optional)_ | SMB password for network shares |
| `cifsdomain` | str | _(optional)_ | SMB domain for network shares |

### Example Configuration

```yaml
ssl: true
certfile: "fullchain.pem"
keyfile: "privkey.pem"
NoAuth: false
disable_thumbnails: false
base_folder: "/share"
localdisks: "sda1,sdb1"
networkdisks: "//192.168.1.100/files,//nas.local/documents"
cifsusername: "fileuser"
cifspassword: "password123"
cifsdomain: "workgroup"
```

## Setup

1. Start the add-on and wait for it to initialize.
1. Access the web interface through the Home Assistant sidebar or at `<your-ip>:8071`.
1. Log in using the default credentials:
   - Username: `admin`
   - Password: `admin`
1. **Important:** Immediately change the default password by clicking on "Settings" > "User Management".
1. Configure your preferred settings through the web interface.
1. If authentication is disabled (`NoAuth: true`), the login screen will be bypassed.

### Mounting Drives

This addon supports mounting both local drives and remote SMB shares:

- **Local drives**: See [Mounting Local Drives in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-Local-Drives-in-Addons)
- **Remote shares**: See [Mounting Remote Shares in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-remote-shares-in-Addons)

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

## Support

Create an issue on GitHub, or ask on the [Home Assistant Community thread](https://community.home-assistant.io/t/home-assistant-addon-filebrowser/282108/3).

[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
