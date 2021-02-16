# Home assistant add-on: alexbelgium

## About
My home assistant addon repository. 
In case of issue, create an issue in the repository and reference the full log from supervisor (all red or white text). 

- ![smb][smb-shield] : allows accessing smb shares, or a local external disk
- ![sql][sql-shield] : requires an external sql database server
- ![stale][stale-shield] : will be updated but not tested each time
- ![privileged][privileged-shield] : requires protection mode off to run

## Installation

Adding this add-ons repository to your Home Assistant instance is
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

### &#10003; [Code-server](code-server/)
- Code-server is VS Code running on a remote server, accessible through the browser.
- Based on https://hub.docker.com/r/linuxserver/code-server

### &#10003; [Doublecommander](doublecommander/) ![smb][smb-shield]
- A free cross platform open source file manager with two panels side by side.
- Based on https://hub.docker.com/r/linuxserver/doublecommander

### &#10003; [Emby](emby/) ![smb][smb-shield]
- A Free Software Media System that puts you in control of managing and streaming your media.
- Based on https://hub.docker.com/r/linuxserver/emby
- Forked from : https://github.com/petersendev/hassio-addons

### &#10003; [Filebrowser](filebrowser/)
- A file manager for the web
- This addon is based on the [docker image](https://hub.docker.com/r/hurlenko/filebrowser).

### &#10003; [Joal](joal/)
- An open source command line RatioMaster with WebUI.

### &#10003; [Nextcloud OCR](nextcloud/) ![smb][smb-shield]
- A Nextcloud container, brought to you by LinuxServer.io. 
- Based on linuxserver image : https://hub.docker.com/r/linuxserver/nextcloud
- Forked from : https://github.com/haberda/hassio_addons

### &#10003; [Papermerge](papermerge/) ![smb][smb-shield]
- Open source document management system (DMS)
- Based on https://hub.docker.com/r/linuxserver/papermerge

### &#10003; [Piwigo](piwigo/) ![smb][smb-shield] ![sql][sql-shield]
- Piwigo is a photo gallery software for the web
- Based on https://hub.docker.com/r/linuxserver/piwigo

### &#10003; [Qbittorrent](qbittorrent/) ![smb][smb-shield]
- Based on https://hub.docker.com/r/linuxserver/qbittorrent

### &#10003; [Radarr](radarr/) ![smb][smb-shield] ![stale][stale-shield]
- A fork of Sonarr to work with movies like Couchpotato	
- Based on https://hub.docker.com/r/linuxserver/radarr

### &#10003; [Scrutiny](scrutiny/) ![privileged][privileged-shield]
- Scrutiny WebUI for smartd S.M.A.R.T monitoring
- Based on https://hub.docker.com/r/linuxserver/scrutiny

### &#10003; [Transmission](transmission/) ![smb][smb-shield] 
- The torrent client for Hass.io.
- Based on https://hub.docker.com/r/linuxserver/transmission

### &#10003; [Ubooquity](ubooquity/) ![smb][smb-shield] 
- Free, lightweight and easy-to-use home server for your comics and ebooks
- Based on https://hub.docker.com/r/linuxserver/ubooquity

[//]: # (ADDONLIST_END)

[stale-shield]: https://img.shields.io/badge/Stale--orange.svg
[smb-shield]: https://img.shields.io/badge/SMB--green?style=plastic.svg
[sql-shield]: https://img.shields.io/badge/SQL-external-orange.svg
[privileged-shield]: https://img.shields.io/badge/privileged-required-orange.svg
 
