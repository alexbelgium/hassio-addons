# Hassio Add-ons by alexbelgium

## About
My hassio addon repository.

## Installation

Adding this add-ons repository to your Hass.io Home Assistant instance is
pretty easy. Follow [the official instructions][third-party-addons] on the
website of Home Assistant, and use the following URL:

```txt
https://github.com/alexbelgium/hassio-addons
```

## Available addons

[//]: # (ADDONLIST_START)

### [emby](emby/)
A Free Software Media System that puts you in control of managing and streaming your media.
- Based on linuxserver image latest beta
- Forked from : https://github.com/petersendev/hassio-addons
- Modifications : switch to beta versions, add smb and local disks mount

### [transmission](transmission/)
The torrent client for Hass.io with OpenVPN support.
- Based on latest transmission
- Forked from : https://github.com/Alexwijn/hassio-addon-transmission
- Modifications : add smb and local disks mount

### [doublecommander](doublecommander/)
A free cross platform open source file manager with two panels side by side.
- Based on latest linuxserver image

[//]: # (ADDONLIST_END)

[third-party-addons]: https://home-assistant.io/hassio/installing_third_party_addons/
