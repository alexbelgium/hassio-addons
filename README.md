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

### [Emby NAS](emby/)
A Free Software Media System that puts you in control of managing and streaming your media.
- Based on linuxserver image latest beta
- Forked from : https://github.com/petersendev/hassio-addons
- Modifications : switch to linuxserver beta versions, add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

### [Transmission](transmission/)
The torrent client for Hass.io.
- Based on linuxserver image
- Modifications :  exposed settings.json in /share/transmission, add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

### [Nextcloud OCR](nextcloud/)
A Nextcloud container, brought to you by LinuxServer.io. 
- Based on linuxserver image
- Forked from : https://github.com/haberda/hassio_addons
- Modifications : update based on images numbering instead of "latest", tesseract for ocr

### [Doublecommander NAS](doublecommander/)
A free cross platform open source file manager with two panels side by side.
- Based on latest linuxserver image
- Modifications : add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

### [Code-server](code-server/)
Code-server is VS Code running on a remote server, accessible through the browser.
- Based on latest linuxserver image

### [Radarr NAS](radarr/)
A fork of Sonarr to work with movies like Couchpotato
- Forked from : https://github.com/petersendev/hassio-addons
- Modifications : add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

[//]: # (ADDONLIST_END)

[third-party-addons]: https://home-assistant.io/hassio/installing_third_party_addons/
