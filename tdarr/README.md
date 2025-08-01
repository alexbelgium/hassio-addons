# Home assistant add-on: Tdarr

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftdarr%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftdarr%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftdarr%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/tdarr/stats.png)

## About

[Tdarr](https://tdarr.io) is a distributed transcoding system for automating media library transcode/remux management using FFmpeg/HandBrake. It ensures your files are exactly how you need them to be in terms of codecs, streams, and containers. Tdarr supports distributed processing, allowing you to put your spare hardware to use with Tdarr Nodes for Windows, Linux (including ARM), and macOS.

Key features:
- Distributed transcoding across multiple nodes
- Automated media library management
- Support for FFmpeg and HandBrake
- Hardware acceleration support
- Web-based management interface
- Plugin-based workflow system

This addon is based on the [docker image](https://hub.docker.com/r/hurlenko/Tdarr) from hurlenko.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for that.

## Configuration

Web UI can be found at `<your-ip>:8265` or through the sidebar using Ingress.
The server port is `8266` for connecting external Tdarr nodes.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `CONFIG_LOCATION` | str | `/config/addons_config/tdarr` | Path where Tdarr config is stored |
| `TZ` | str | | Timezone (e.g., `Europe/London`) |
| `localdisks` | str | | Local drives to mount (e.g., `sda1,sdb1,MYNAS`) |
| `networkdisks` | str | | SMB shares to mount (e.g., `//SERVER/SHARE`) |
| `cifsusername` | str | | SMB username for network shares |
| `cifspassword` | str | | SMB password for network shares |
| `cifsdomain` | str | | SMB domain for network shares |

### Example Configuration

```yaml
CONFIG_LOCATION: "/config/addons_config/tdarr"
TZ: "Europe/London"
localdisks: "sda1,sdb1"
networkdisks: "//192.168.1.100/media,//nas.local/transcoding"
cifsusername: "mediauser"
cifspassword: "password123"
cifsdomain: "workgroup"
```

### Setting up Distributed Transcoding

1. **Configure the Server**: 
   - Access the Web UI at `<your-ip>:8265`
   - Set up your media libraries and transcoding settings
   - Configure plugins and workflows as needed

2. **Add External Nodes**:
   - Install Tdarr Node on additional machines
   - Point them to your Home Assistant IP on port `8266`
   - Nodes will automatically register and appear in the Web UI

3. **Hardware Acceleration**:
   - The addon includes hardware acceleration support
   - Configure GPU transcoding in the Tdarr Web UI settings
   - Supported acceleration: Intel QuickSync, NVIDIA NVENC, AMD VCE

### Mounting Drives

This addon supports mounting both local drives and remote SMB shares:

- **Local drives**: See [Mounting Local Drives in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-Local-Drives-in-Addons)
- **Remote shares**: See [Mounting Remote Shares in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-remote-shares-in-Addons)

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

### Hardware Acceleration Notes

The addon includes device access for hardware acceleration:
- Intel QuickSync: `/dev/dri` devices are mapped
- NVIDIA: Environment variables are set for GPU detection
- AMD: Hardware acceleration supported through available devices

Configure hardware acceleration in the Tdarr Web UI under Settings > FFmpeg/HandBrake settings.

## Support

- Official Tdarr documentation: [https://docs.tdarr.io/](https://docs.tdarr.io/)
- Create an issue on [GitHub](https://github.com/alexbelgium/hassio-addons/issues)
- Ask on the [Home Assistant Community thread](https://community.home-assistant.io/t/home-assistant-addon-tdarr/282108/3)

[repository]: https://github.com/alexbelgium/hassio-addons
