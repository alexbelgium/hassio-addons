# Home assistant add-on: alexbelgium

## About

My home assistant addon repository.
In case of issue, create an issue in the repository and reference the full log from supervisor (all red or white text).

- ![smb][smb-shield] : allows accessing smb shares, or a local external disk
- ![sql][sql-shield] : requires an external sql database server
- ![base][base-shield] : will be updated but not tested each time
- ![privileged][privileged-shield] : requires protection mode off to run
- ![ingress][ingress-shield] : supports Ingress
## Installation

Adding this add-ons repository to your Home Assistant instance is
pretty easy. Follow [the official instructions](https://home-assistant.io/hassio/installing_third_party_addons) on the
website of Home Assistant, and use the following URL:

```
https://github.com/alexbelgium/hassio-addons
```

## Available addons

[//]: # "ADDONLIST_START"

### &#10003; [Addons Updater](addons_updater/) ![support][support-shield]

- Automatic addons update by aligning version tag with github upstream releases
- Support : [[New addon] automatically update addons based on github upstream new releases - Share your Projects! - Home Assistant Community (home-assistant.io)](https://community.home-assistant.io/t/new-addon-automatically-update-addons-based-on-github-upstream-new-releases/275416)

### &#10003; [Bazarr](bazarr/) ![smb][smb-shield]  ![base][base-shield]

- Companion application to Sonarr and Radarr to download subtitles
- Based on https://hub.docker.com/r/linuxserver/bazarr

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

### &#10003; [Filebrowser](filebrowser/)  ![support][support-shield]

- A file manager for the web
- This addon is based on the [docker image](https://hub.docker.com/r/hurlenko/filebrowser).
- Support : [Home Assistant addon : FileBrowser - Home Assistant OS - Home Assistant Community (home-assistant.io)](https://community.home-assistant.io/t/home-assistant-addon-filebrowser/282108)

### &#10003; [Jackett](jackett/) ![smb][smb-shield] ![base][base-shield]

- Translates queries from apps (Sonarr, SickRage, CouchPotato, Mylar, etc) into tracker-site-specific http queries, parses the html response, then sends results back to the requesting software
- Based on https://hub.docker.com/r/linuxserver/jackett

### &#10003; [Jellyfin](jellyfin/) ![smb][smb-shield]

- A Free Software Media System that puts you in control of managing and streaming your media.
- Based on https://hub.docker.com/r/linuxserver/jellyfin

### &#10003; [Joal](joal/) ![ingress][ingress-shield]

- An open source command line RatioMaster with WebUI.

### &#10003; [Nextcloud OCR](nextcloud/) ![smb][smb-shield]

- A Nextcloud container, brought to you by LinuxServer.io.
- Based on linuxserver image : https://hub.docker.com/r/linuxserver/nextcloud
- Forked from : https://github.com/haberda/hassio_addons

### &#10003; [Papermerge](papermerge/)

- An HTPC/Homelab services organizer that is written in PHP
- Based on https://hub.docker.com/r/linuxserver/organizr

### &#10003; [Papermerge](papermerge/) ![smb][smb-shield]

- Open source document management system (DMS)
- Based on https://hub.docker.com/r/linuxserver/papermerge

### &#10003; [Portainer](portainer/) ![privileged][privileged-shield] ![ingress][ingress-shield] 

- Forked from : https://github.com/hassio-addons/addon-portainer
- Updated to latest version, add webui, ssl, password management

### &#10003; [Piwigo](piwigo/) ![smb][smb-shield] ![sql][sql-shield] ![base][base-shield]

- Piwigo is a photo gallery software for the web
- Based on https://hub.docker.com/r/linuxserver/piwigo

### &#10003; [Plex](plex/) ![smb][smb-shield] 

- Plex organizes video, music and photos from personal media libraries and streams them to smart TVs, streaming boxes and mobile devices.
- Based on https://hub.docker.com/r/linuxserver/plex

### &#10003; [Prowlarr](prowlarr/) ![smb][smb-shield] ![base][base-shield]

- Torrent Trackers and Usenet Indexers offering complete management ofSonarr, Radarr, Lidarr, and Readarr indexers with no per app setup required
- Based on https://hub.docker.com/r/linuxserver/prowlarr

### &#10003; [Qbittorrent](qbittorrent/) ![smb][smb-shield]  ![support][support-shield] ![ingress][ingress-shield]

- Based on https://hub.docker.com/r/linuxserver/qbittorrent
- Support : [Home Assistant addon : qbittorrent (supports openvpn & smb mounts) - Home Assistant OS - Home Assistant Community (home-assistant.io)](https://community.home-assistant.io/t/home-assistant-addon-qbittorrent-supports-openvpn-smb-mounts/279247)

### &#10003; [Radarr](radarr/) ![smb][smb-shield] ![base][base-shield]

- A fork of Sonarr to work with movies like Couchpotato
- Based on https://hub.docker.com/r/linuxserver/radarr

### &#10003; [Sonarr](sonarr/) ![smb][smb-shield] ![base][base-shield]

- Can monitor multiple RSS feeds for new episodes of your favorite shows and will grab, sort and rename them.
- Based on https://hub.docker.com/r/linuxserver/sonarr

### &#10003; [Scrutiny](scrutiny/)  ![support][support-shield] ![ingress][ingress-shield]

- Scrutiny WebUI for smartd S.M.A.R.T monitoring
- Based on https://hub.docker.com/r/linuxserver/scrutiny
- Support : [Home assistant addon : Scrutiny (SMART dashboard) - Home Assistant OS - Home Assistant Community (home-assistant.io)](https://community.home-assistant.io/t/home-assistant-addon-scrutiny-smart-dashboard/295747)

### &#10003; [Transmission](transmission/) ![smb][smb-shield]

- The torrent client for Hass.io.
- Based on https://hub.docker.com/r/linuxserver/transmission

### &#10003; [Ubooquity](ubooquity/) ![smb][smb-shield]  ![support][support-shield]

- Free, lightweight and easy-to-use home server for your comics and ebooks
- Based on https://hub.docker.com/r/linuxserver/ubooquity
- Support : [Home assistant addon : Ubooquity (=Plex for books and comics) - Home Assistant OS - Home Assistant Community (home-assistant.io)](https://community.home-assistant.io/t/home-assistant-addon-ubooquity-plex-for-books-and-comics/283811)

[//]: # "ADDONLIST_END"
[base-shield]: https://img.shields.io/badge/Basic--orange.svg
[smb-shield]: https://img.shields.io/badge/SMB--green?style=plastic.svg
[sql-shield]: https://img.shields.io/badge/SQL-external-orange.svg
[privileged-shield]: https://img.shields.io/badge/privileged-required-orange.svg
[ingress-shield]: https://img.shields.io/badge/ingress--green.svg
[support-shield]: https://img.shields.io/badge/Support-thread-green.svg 
