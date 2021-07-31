# Home assistant add-on: alexbelgium

## About

My home assistant addon repository.
In case of issue, create an issue in the repository and reference the full log from supervisor (all red or white text).

- ![smb][smb-shield] : allows accessing smb shares, or a local external disk
- ![ingress][ingress-shield] : supports Ingress
- ![sql][sql-shield] : requires an external sql database server
- ![base][base-shield] : will be updated but not tested each time
- ![privileged][privileged-shield] : requires protection mode off to run
- ![ram][ram-shield] : a minimum of 4gb of RAM is recommended to avoid crashing the system

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

### &#10003; [Flexget](flexget/)

- FlexGet is a multipurpose automation tool for all of your media
- Based on https://hub.docker.com/r/wiserain/flexget
- Developed for @TyjTyj

### &#10003; [Inadyn](inadyn/)

- Inadyn, or In-a-Dyn, is a small and simple Dynamic DNS, DDNS, client with HTTPS support. Commonly available in many GNU/Linux distributions, used in off the shelf routers and Internet gateways to automate the task of keeping your Internet name in sync with your public¹ IP address. It can also be used in installations with redundant (backup) connections to the Internet.
- Based on https://hub.docker.com/r/troglobit/inadyn

### &#10003; [Jackett](jackett/) ![smb][smb-shield] ![base][base-shield]

- Translates queries from apps (Sonarr, SickRage, CouchPotato, Mylar, etc) into tracker-site-specific http queries, parses the html response, then sends results back to the requesting software
- Based on https://hub.docker.com/r/linuxserver/jackett

### &#10003; [Jellyfin](jellyfin/) ![smb][smb-shield]

- A Free Software Media System that puts you in control of managing and streaming your media.
- Based on https://hub.docker.com/r/linuxserver/jellyfin

### &#10003; [Joal](joal/) ![ingress][ingress-shield]

- An open source command line RatioMaster with WebUI.

### &#10003; [Mealie](mealie/)
- Mealie is a self hosted recipe manager and meal planner with a RestAPI backend and a reactive frontend application built in Vue for a pleasant user experience for the whole family. This addon is based on the docker image from hay-kot.
- Based on docker : https://hub.docker.com/r/hkotel/mealie

### &#10003; [Nextcloud OCR](nextcloud/) ![smb][smb-shield]

- A Nextcloud container, brought to you by LinuxServer.io.
- Based on linuxserver image : https://hub.docker.com/r/linuxserver/nextcloud
- Forked from : https://github.com/haberda/hassio_addons

### &#10003; [Ombi](ombi/)

- Self-hosted Plex Request and user management system
- Based on https://hub.docker.com/r/linuxserver/ombi

### &#10003; [Organizr](organizr/)

- An HTPC/Homelab services organizer that is written in PHP
- Based on https://hub.docker.com/r/linuxserver/organizr

### &#10003; [Papermerge](papermerge/) ![smb][smb-shield]

- Open source document management system (DMS)
- Based on https://hub.docker.com/r/linuxserver/papermerge

### &#10003; [Photoprism](photoprism/) ![smb][smb-shield] ![sql][sql-shield] ![ram][ram-shield]

- Piwigo is a photo gallery software for the web
- Based on https://hub.docker.com/r/linuxserver/piwigo

### &#10003; [Piwigo](piwigo/) ![smb][smb-shield] ![sql][sql-shield] ![base][base-shield]

- Piwigo is a photo gallery software for the web
- Based on https://hub.docker.com/r/linuxserver/piwigo
- 
### &#10003; [Portainer](portainer/) ![privileged][privileged-shield] ![ingress][ingress-shield] 

- Forked from : https://github.com/hassio-addons/addon-portainer
- Updated to latest version, add webui, ssl, password management

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

### &#10003; [Resioliosync](resiolosync/) ![smb][smb-shield] ![base][base-shield]

- Self-hosted file share and collaboration platform on the web
- Based on https://hub.docker.com/r/linuxserver/resiolio-sync
- Developed by @TyjTyj

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

### &#10003; [Ubooquity](ubooquity/) ![smb][smb-shield]  ![support][support-shield] ![ram][ram-shield]

- Free, lightweight and easy-to-use home server for your comics and ebooks
- Based on https://hub.docker.com/r/linuxserver/ubooquity
- Support : [Home assistant addon : Ubooquity (=Plex for books and comics) - Home Assistant OS - Home Assistant Community (home-assistant.io)](https://community.home-assistant.io/t/home-assistant-addon-ubooquity-plex-for-books-and-comics/283811)

### &#10003; [xTeVe](xteve/)

- M3U Proxy for Plex DVR and Emby Live TV.
- Based on https://hub.docker.com/r/tnwhitwell/xteve

[//]: # "ADDONLIST_END"
[base-shield]: https://img.shields.io/badge/Basic--orange.svg
[smb-shield]: https://img.shields.io/badge/SMB--green?style=plastic.svg
[sql-shield]: https://img.shields.io/badge/SQL-external-orange.svg
[privileged-shield]: https://img.shields.io/badge/privileged-required-orange.svg
[ingress-shield]: https://img.shields.io/badge/ingress--green.svg
[support-shield]: https://img.shields.io/badge/Support-thread-green.svg 
[ram-shield]: https://img.shields.io/badge/RAM_min-4Gb-orange.svg 
