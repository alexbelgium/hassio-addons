# Home assistant add-on: alexbelgium

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
![update-badge]

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[update-badge]: https://img.shields.io/github/last-commit/alexbelgium/hassio-addons?label=last%20update

## About

My home assistant addon repository.
In case of issue, create an issue in the repository and reference the full log from supervisor (all red or white text).

- ![smb][smb-shield] : allows accessing smb shares, or a local external disk
- ![ingress][ingress-shield] : supports Ingress
- ![sql][sql-shield] : requires an external sql database server
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

Automatic addons update by aligning version tag with github upstream releases

### &#10003; [Bazarr](bazarr/) ![smb][smb-shield]

Companion application to Sonarr and Radarr to download subtitles

### &#10003; [Bitwarden](bitwarden/)

Open source password management solution

### &#10003; [Code-server](code-server/)

Code-server is VS Code running on a remote server, accessible through the browser.

### &#10003; [Doublecommander](doublecommander/) ![smb][smb-shield]

A free cross platform open source file manager with two panels side by side.

### &#10003; [Emby](emby/) ![smb][smb-shield]

A Free Software Media System that puts you in control of managing and streaming your media.

### &#10003; [Grav](grav/) ![smb][smb-shield]

Fast, Simple, and Flexible, file-based Web-platform

### &#10003; [Filebrowser](filebrowser/) ![support][support-shield]![smb][smb-shield]

A file manager for the web

### &#10003; [Flexget](flexget/)

FlexGet is a multipurpose automation tool for all of your media (Developed for @TyjTyj)

### &#10003; [Inadyn](inadyn/)

Inadyn, or In-a-Dyn, is a small and simple Dynamic DNS, DDNS, client with HTTPS support. Commonly available in many GNU/Linux distributions, used in off the shelf routers and Internet gateways to automate the task of keeping your Internet name in sync with your public¹ IP address. It can also be used in installations with redundant (backup) connections to the Internet.

### &#10003; [Jackett](jackett/) ![smb][smb-shield]

Translates queries from apps (Sonarr, SickRage, CouchPotato, Mylar, etc) into tracker-site-specific http queries, parses the html response, then sends results back to the requesting software

### &#10003; [Jellyfin](jellyfin/) ![smb][smb-shield]

A Free Software Media System that puts you in control of managing and streaming your media.

### &#10003; [Joal](joal/) ![ingress][ingress-shield]

An open source command line RatioMaster with WebUI.

### &#10003; [Mealie](mealie/)

Mealie is a self hosted recipe manager and meal planner with a RestAPI backend and a reactive frontend application built in Vue for a pleasant user experience for the whole family. This addon is based on the docker image from hay-kot.

### &#10003; [Nextcloud OCR](nextcloud/) ![smb][smb-shield]

A Nextcloud container, brought to you by LinuxServer.io.

### &#10003; [Ombi](ombi/)

Self-hosted Plex Request and user management system

### &#10003; [Organizr](organizr/)

An HTPC/Homelab services organizer that is written in PHP

### &#10003; [Papermerge](papermerge/) ![smb][smb-shield]

Open source document management system (DMS)

### &#10003; [Photoprism](photoprism/) ![smb][smb-shield] ![sql][sql-shield] ![ram][ram-shield]

server-based application for browsing, organizing and sharing your personal photo collection

### &#10003; [Piwigo](piwigo/) ![smb][smb-shield] ![sql][sql-shield]

photo gallery software for the web

### &#10003; [Portainer](portainer/) ![privileged][privileged-shield] ![ingress][ingress-shield]

Manage your docker environment

### &#10003; [Plex](plex/) ![smb][smb-shield]

Plex organizes video, music and photos from personal media libraries and streams them to smart TVs, streaming boxes and mobile devices.

### &#10003; [Prowlarr](prowlarr/) ![smb][smb-shield]

Torrent Trackers and Usenet Indexers offering complete management ofSonarr, Radarr, Lidarr, and Readarr indexers with no per app setup required

### &#10003; [Qbittorrent](qbittorrent/) ![smb][smb-shield] ![support][support-shield] ![ingress][ingress-shield]

Torrent manager with custom ui and many configurable options

### &#10003; [Radarr](radarr/) ![smb][smb-shield]

A fork of Sonarr to work with movies like Couchpotato

### &#10003; [Readarr](readarr/) ![smb][smb-shield]

Book Manager and Automation

### &#10003; [Requestrr](requestrr/)

Chatbot used to simplify using services like Sonarr/Radarr/Ombi via the use of chat

### &#10003; [Resioliosync](resiolosync/) ![smb][smb-shield]

Self-hosted file share and collaboration platform on the Web (dev by @TyjTyj)

### &#10003; [Sonarr](sonarr/) ![smb][smb-shield]

Can monitor multiple RSS feeds for new episodes of your favorite shows and will grab, sort and rename them.

### &#10003; [Scrutiny](scrutiny/) ![support][support-shield] ![ingress][ingress-shield]

Scrutiny WebUI for smartd S.M.A.R.T monitoring

### &#10003; [Teamspeak](teamspeak/)

Voice communication for online gaming, education and training.

### &#10003; [Transmission](transmission/) ![smb][smb-shield]

The torrent client for Hass.io.

### &#10003; [Ubooquity](ubooquity/) ![smb][smb-shield] ![support][support-shield] ![ram][ram-shield]

Free, lightweight and easy-to-use home server for your comics and ebooks

### &#10003; [Webtrees](webtrees/)

web's leading online collaborative genealogy application

### &#10003; [Wger](wger/)

manage your personal workouts, weight and diet plans

### &#10003; [xTeVe](xteve/)

M3U Proxy for Plex DVR and Emby Live TV.

[//]: # "ADDONLIST_END"
[smb-shield]: https://img.shields.io/badge/SMB--green?style=plastic.svg
[sql-shield]: https://img.shields.io/badge/SQL-external-orange.svg
[privileged-shield]: https://img.shields.io/badge/privileged-required-orange.svg
[ingress-shield]: https://img.shields.io/badge/ingress--green.svg
[support-shield]: https://img.shields.io/badge/Support-thread-green.svg
[ram-shield]: https://img.shields.io/badge/RAM_min-4Gb-orange.svg
