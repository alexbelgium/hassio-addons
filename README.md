# Home assistant add-on: alexbelgium

## About
My home assistant addon repository

## Installation

Adding this add-ons repository to your Hass.io Home Assistant instance is
pretty easy. Follow [the official instructions](https://home-assistant.io/hassio/installing_third_party_addons) on the
website of Home Assistant, and use the following URL: 
```
https://github.com/alexbelgium/hassio-addons
```

## Available addons

[//]: # (ADDONLIST_START)

### &#10003; [Addons Updater](addons_updater/)
- Automatic addons update by aligning version tag with github upstream releases

### &#10003; [Bitwarden](bitwarden/)
- Open source password management solution
- Forked from : https://github.com/hassio-addons/addon-bitwarden
- Modifications : updated version

### &#10003; [Cloudcommander](cloudcommander/) ![stale][stale-shield]
- Cloud Commander a file manager for the web with console and editor.
- This addon is based on the [docker image](https://hub.docker.com/r/coderaiser/cloudcmd).

### &#10003; [Code-server](code-server/)
- Code-server is VS Code running on a remote server, accessible through the browser.
- Based on latest linuxserver image https://hub.docker.com/r/linuxserver/code-server

### &#10003; [Doublecommander](doublecommander/) ![smb][smb-shield]
- A free cross platform open source file manager with two panels side by side.
- Based on latest linuxserver image
- Modifications : add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

### &#10003; [Emby](emby/) ![smb][smb-shield]
- A Free Software Media System that puts you in control of managing and streaming your media.
- Based on linuxserver image latest beta : https://hub.docker.com/r/linuxserver/emby
- Forked from : https://github.com/petersendev/hassio-addons
- Modifications : switch to linuxserver beta versions, add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

### &#10003; [Joal](joal/)
- An open source command line RatioMaster with WebUI.

### &#10003; [Nextcloud OCR](nextcloud/)
- A Nextcloud container, brought to you by LinuxServer.io. 
- Based on linuxserver image : https://hub.docker.com/r/linuxserver/nextcloud
- Forked from : https://github.com/haberda/hassio_addons
- Modifications : update based on images numbering instead of "latest", tesseract for ocr

### &#10003; [Papermerge](papermerge/) ![stale][stale-shield]
- Open source document management system (DMS)
- Based on linuxserver image : https://hub.docker.com/r/linuxserver/papermerge

### &#10003; [Qbittorrent](qbittorrent/) ![smb][smb-shield]
- Based on linuxserver image : https://hub.docker.com/r/linuxserver/qbittorrent

### &#10003; [Radarr](radarr/) ![smb][smb-shield] ![stale][stale-shield]
- A fork of Sonarr to work with movies like Couchpotato	
- Forked from : https://hub.docker.com/r/linuxserver/radarr
- Modifications : add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

### &#10003; [Transmission](transmission/) ![smb][smb-shield] 
- The torrent client for Hass.io.
- Based on linuxserver image : https://hub.docker.com/r/linuxserver/transmission
- Modifications :  exposed settings.json in /share/transmission, add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

[//]: # (ADDONLIST_END)

[stale-shield]: https://img.shields.io/badge/-Stale-lightgrey
[smb-shield]: https://img.shields.io/badge/SMB--green?style=plastic.svg
