# About
My home assistant addon repository, by alexbelgium

# Installation

Adding this add-ons repository to your Hass.io Home Assistant instance is
pretty easy. Follow [the official instructions](https://home-assistant.io/hassio/installing_third_party_addons) on the
website of Home Assistant, and use the following URL: 
```
https://github.com/alexbelgium/hassio-addons
```

# Available addons

[//]: # (ADDONLIST_START)

### [Addons Updater](addons_updater/)
- Automatic addons update by aligning version tag with github upstream releases

### [Bitwarden](bitwarden/)
- Open source password management solution
- Forked from : https://github.com/hassio-addons/addon-bitwarden
- Modifications : updated version

### [Cloudcommander](cloudcommander/) <sub><i>stale</i></sub>
- Cloud Commander a file manager for the web with console and editor.
- This addon is based on the [docker image](https://hub.docker.com/r/coderaiser/cloudcmd).

### [Code-server](code-server/)
- Code-server is VS Code running on a remote server, accessible through the browser.
- Based on latest linuxserver image https://hub.docker.com/r/linuxserver/code-server

### [Doublecommander NAS](doublecommander/)
- A free cross platform open source file manager with two panels side by side.
- Based on latest linuxserver image
- Modifications : add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

### [Emby NAS](emby/)
- A Free Software Media System that puts you in control of managing and streaming your media.
- Based on linuxserver image latest beta : https://hub.docker.com/r/linuxserver/emby
- Forked from : https://github.com/petersendev/hassio-addons
- Modifications : switch to linuxserver beta versions, add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

### [Joal](joal/)
- An open source command line RatioMaster with WebUI.

### [Nextcloud OCR](nextcloud/)
- A Nextcloud container, brought to you by LinuxServer.io. 
- Based on linuxserver image : https://hub.docker.com/r/linuxserver/nextcloud
- Forked from : https://github.com/haberda/hassio_addons
- Modifications : update based on images numbering instead of "latest", tesseract for ocr

### [Papermerge)](papermerge/) <sub><i>stale</i></sub>
- Open source document management system (DMS)
- Based on linuxserver image : https://hub.docker.com/r/linuxserver/papermerge

### [Qbittorrent)](qbittorrent/)
- Based on linuxserver image : https://hub.docker.com/r/linuxserver/qbittorrent

### [Radarr NAS](radarr/) <sub><i>stale</i></sub>
- A fork of Sonarr to work with movies like Couchpotato	
- Forked from : https://hub.docker.com/r/linuxserver/radarr
- Modifications : add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

### [Transmission](transmission/)
- The torrent client for Hass.io.
- Based on linuxserver image : https://hub.docker.com/r/linuxserver/transmission
- Modifications :  exposed settings.json in /share/transmission, add smb and local disks mount [(@dianlight)](https://github.com/dianlight)

[//]: # (ADDONLIST_END)
