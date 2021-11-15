# Home assistant add-on: alexbelgium

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
![update-badge]

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[update-badge]: https://img.shields.io/github/last-commit/alexbelgium/hassio-addons?label=last%20update

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

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

[//]: # "ADDONLIST_START"

## &#10003; Comics management

- [Ubooquity](ubooquity/) ![smb][smb-shield] ![support][support-shield] ![ram][ram-shield]: Free, lightweight and easy-to-use home server for your comics and ebooks !

## &#10003; Documents management

- [Nextcloud OCR](nextcloud/) ![smb][smb-shield] : A Nextcloud container, brought to you by LinuxServer.io.
- [Papermerge](papermerge/) ![smb][smb-shield] : Open source document management system (DMS)
- [Elasticsearch](elasticsearch/) : distributed, RESTful search and analytics engine capable of solving a growing number of use cases

## &#10003; File explorers

- [Cloudcommander](cloudcommander/) ![smb][smb-shield] : File manager
- [Doublecommander](doublecommander/) ![smb][smb-shield] : A free cross platform open source file manager with two panels side by side.
- [Filebrowser](filebrowser/) ![support][support-shield]![smb][smb-shield] : A file manager for the web

## &#10003; Images management

- [Photoprism](photoprism/) ![smb][smb-shield] ![sql][sql-shield] ![ram][ram-shield] : server-based application for browsing, organizing and sharing your personal photo collection
- [Piwigo](piwigo/) ![smb][smb-shield] ![sql][sql-shield] : photo gallery software for the web

## &#10003; Home & family

- [Enedisgateway2mqtt](enedisgateway2mqtt) : use Enedis Gateway API to send data in your MQTT Broker
- [Mealie](mealie/) : Mealie is a self hosted recipe manager and meal planner with a RestAPI backend and a reactive frontend application built in Vue for a pleasant user experience for the whole family. This addon is based on the docker image from hay-kot.
- [Wger](wger/): manage your personal workouts, weight and diet plans

## &#10003; Genealogy

- [Webtrees](webtrees/): web's leading online collaborative genealogy application

## &#10003; Misc tools

- [Addons Updater](addons_updater/) ![support][support-shield] : Automatic addons update by aligning version tag with github upstream releases
- [Code-server](code-server/) : Code-server is VS Code running on a remote server, accessible through the browser.
- [Inadyn](inadyn/) : Inadyn, or In-a-Dyn, is a small and simple Dynamic DNS, DDNS, client with HTTPS support. Commonly available in many GNU/Linux distributions, used in off the shelf routers and Internet gateways to automate the task of keeping your Internet name in sync with your public¹ IP address. It can also be used in installations with redundant (backup) connections to the Internet.
- [Portainer](portainer/) ![privileged][privileged-shield] ![ingress][ingress-shield] : Manage your docker environment
- [Scrutiny](scrutiny/) ![support][support-shield] ![ingress][ingress-shield]: Scrutiny WebUI for smartd S.M.A.R.T monitoring
- [Teamspeak](teamspeak/): Voice communication for online gaming, education and training.

## &#10003; Multimedia distributors

- [Booksonic-air](booksonic_air/) ![smb][smb-shield]: platform for accessing the audibooks you own wherever you are
- [Emby](emby/) ![smb][smb-shield]: A Free Software Media System that puts you in control of managing and streaming your media.
- [Flexget](flexget/) : FlexGet is a multipurpose automation tool for all of your media (Developed for @TyjTyj)
- [Jellyfin](jellyfin/) ![smb][smb-shield] : A Free Software Media System that puts you in control of managing and streaming your media.
- [Ombi](ombi/) : Self-hosted Plex Request and user management system
- [Plex](plex/) ![smb][smb-shield] : Plex organizes video, music and photos from personal media libraries and streams them to smart TVs, streaming boxes and mobile devices.
- [xTeVe](xteve/): M3U Proxy for Plex DVR and Emby Live TV.

## &#10003; Multimedia downloaders

- [Bazarr](bazarr/) ![smb][smb-shield] : Companion application to Sonarr and Radarr to download subtitles
- [Jackett](jackett/) ![smb][smb-shield] : Translates queries from apps (Sonarr, SickRage, CouchPotato, Mylar, etc) into tracker-site-specific http queries, parses the html response, then sends results back to the requesting software
- [Prowlarr](prowlarr/) ![smb][smb-shield] : Torrent Trackers and Usenet Indexers offering complete management ofSonarr, Radarr, Lidarr, and Readarr indexers with no per app setup required
- [Radarr](radarr/) ![smb][smb-shield] : A fork of Sonarr to work with movies like Couchpotato
- [Readarr](readarr/) ![smb][smb-shield] : Book Manager and Automation
- [Requestrr](requestrr/) : Chatbot used to simplify using services like Sonarr/Radarr/Ombi via the use of chat
- [Sonarr](sonarr/) ![smb][smb-shield] : Can monitor multiple RSS feeds for new episodes of your favorite shows and will grab, sort and rename them.

## &#10003; Organizers

- [Organizr](organizr/) : An HTPC/Homelab services organizer that is written in PHP

## &#10003; Security tools

- [Bitwarden](bitwarden/) : Open source password management solution

## &#10003; Torrent tools

- [Joal](joal/) ![ingress][ingress-shield] : An open source command line RatioMaster with WebUI.
- [Qbittorrent](qbittorrent/) ![smb][smb-shield] ![support][support-shield] ![ingress][ingress-shield] : Torrent manager with custom ui and many configurable options
- [Transmission](transmission/) ![smb][smb-shield] : The torrent client for Hass.io.

## &#10003; Web hosting

- [Grav](grav/) ![smb][smb-shield] : Fast, Simple, and Flexible, file-based Web-platform
- [Resioliosync](resiolosync/) ![smb][smb-shield]: Self-hosted file share and collaboration platform on the Web (dev by @TyjTyj)

[//]: # "ADDONLIST_END"
[smb-shield]: https://img.shields.io/badge/SMB--green?style=plastic.svg
[sql-shield]: https://img.shields.io/badge/SQL-external-orange.svg
[privileged-shield]: https://img.shields.io/badge/privileged-required-orange.svg
[ingress-shield]: https://img.shields.io/badge/ingress--green.svg
[support-shield]: https://img.shields.io/badge/Support-thread-green.svg
[ram-shield]: https://img.shields.io/badge/RAM_min-4Gb-orange.svg
