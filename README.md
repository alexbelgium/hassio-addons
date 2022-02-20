# Home assistant add-on: alexbelgium

<!-- markdownlint-disable MD033 -->

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
![update-badge](https://img.shields.io/github/last-commit/alexbelgium/hassio-addons?label=last%20update)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

[![GitHub Super-Linter](https://github.com/alexbelgium/hassio-addons/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Builder](https://github.com/alexbelgium/hassio-addons/workflows/Builder/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/builder.yaml)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=alexbelgium/hassio-addons&amp;utm_campaign=Badge_Grade)

[support-badge]: https://camo.githubusercontent.com/f4dbb995049f512fdc97fcc9e022ac243fa38c408510df9d46c7467d0970d959/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f537570706f72742d7468726561642d677265656e2e737667

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

_Thanks to all contributors !_

<a href="https://github.com/alexbelgium/hassio-addons/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=alexbelgium/hassio-addons" />
</a>

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

```yaml
https://github.com/alexbelgium/hassio-addons
```

[//]: # "ADDONLIST_START"

## &#10003; Connectors

- [enedisgateway2mqtt](enedisgateway2mqtt/) : use Enedis Gateway API to send data in your MQTT Broker
- [gazpar2mqtt](gazpar2mqtt/) : Python script to fetch GRDF data and publish data to a mqtt broker

## &#10003; Comics management

- [Ubooquity](ubooquity/) ![smb][smb-shield] ![support][support-shield] ![ram][ram-shield]: Free, lightweight and easy-to-use home server for your comics and ebooks !

## &#10003; Documents management

- [Nextcloud OCR](nextcloud/) ![smb][smb-shield] : A Nextcloud container, brought to you by LinuxServer.io
- [Paperless NG](paperless_ng/) ![smb][smb-shield] : scan, index and archive all your physical documents
- [Papermerge](papermerge/) ![smb][smb-shield] : Open source document management system (DMS)
- [Elasticsearch](elasticsearch/) : distributed, RESTful search and analytics engine capable of solving a growing number of use cases

## &#10003; File explorers

- [Cloudcommander](cloudcommander/) ![smb][smb-shield] : File manager
- [Filebrowser](filebrowser/) ![support][support-shield]![smb][smb-shield] : A file manager for the web

## &#10003; Images management

- [Photoprism](photoprism/) ![smb][smb-shield] ![sql][sql-shield] ![ram][ram-shield] : server-based application for browsing, organizing and sharing your personal photo collection
- [Piwigo](piwigo/) ![smb][smb-shield] ![sql][sql-shield] : photo gallery software for the web

## &#10003; Home & family

- [Enedisgateway2mqtt](enedisgateway2mqtt) : use Enedis Gateway API to send data in your MQTT Broker
- [Firefly III](fireflyiii/) : A free and open source personal finance manager
- [Firefly III Data Importer](fireflyiii_data_importer/) : Data importer for Firefly III
- [Mealie](mealie/) : Mealie is a self hosted recipe manager and meal planner with a RestAPI backend and a reactive frontend application built in Vue for a pleasant user experience for the whole family. This addon is based on the docker image from hay-kot.
- [Tandoor Recipes](tandoor_recipes/): Recipe manager
- [Wger](wger/): manage your personal workouts, weight and diet plans

## &#10003; Genealogy

- [Webtrees](webtrees/): web's leading online collaborative genealogy application

## &#10003; Misc tools

- [Addons Updater](addons_updater/) [![Support Thread][support-badge]](https://community.home-assistant.io/t/new-addon-automatically-update-addons-based-on-github-upstream-new-releases/) : Automatic addons update by aligning version tag with github upstream releases
- [Arpspoof](arpspoof/): adds ability to block internet connection for local network devices
- [Code-server](code-server/) : Code-server is VS Code running on a remote server, accessible through the browser.
- [Inadyn](inadyn/) : Inadyn, or In-a-Dyn, is a small and simple Dynamic DNS, DDNS, client with HTTPS support. Commonly available in many GNU/Linux distributions, used in off the shelf routers and Internet gateways to automate the task of keeping your Internet name in sync with your public¹ IP address. It can also be used in installations with redundant (backup) connections to the Internet.
- [Portainer](portainer/) ![privileged][privileged-shield] ![ingress][ingress-shield] : Manage your docker environment
- [Scrutiny](scrutiny/) ![support][support-shield] ![ingress][ingress-shield]: Scrutiny WebUI for smartd S.M.A.R.T monitoring
- [Spotweb](spotweb/) : Spotweb is a decentralized usenet community based on the Spotnet protocol
- [Teamspeak](teamspeak/): Voice communication for online gaming, education and training.

## &#10003; Multimedia distributors

- [Booksonic-air](booksonic_air/) ![smb][smb-shield]: platform for accessing the audibooks you own wherever you are
- [Emby](emby/) ![smb][smb-shield]: A Free Software Media System that puts you in control of managing and streaming your media.
- [Flexget](flexget/) : FlexGet is a multipurpose automation tool for all of your media (Developed for @TyjTyj)
- [Jellyfin](jellyfin/) ![smb][smb-shield] : A Free Software Media System that puts you in control of managing and streaming your media.
- [Mylar3](mylar3/) ![smb][smb-shield] : automated Comic Book downloader (cbr/cbz) for use with NZB and torrents written in python. It supports SABnzbd, NZBGET, and many torrent clients in addition to DDL.
- [Ombi](ombi/) : Self-hosted Plex Request and user management system
- [Plex](plex/) ![smb][smb-shield] : Plex organizes video, music and photos from personal media libraries and streams them to smart TVs, streaming boxes and mobile devices.
- [xTeVe](xteve/): M3U Proxy for Plex DVR and Emby Live TV.

## &#10003; Multimedia downloaders

- [Bazarr](bazarr/) ![smb][smb-shield] : Companion application to Sonarr and Radarr to download subtitles
- [FlareSolverr](flaresolverr/) : Proxy server to bypass Cloudflare protection
- [Jackett](jackett/) ![smb][smb-shield] : Translates queries from apps (Sonarr, SickRage, CouchPotato, Mylar, etc) into tracker-site-specific http queries, parses the html response, then sends results back to the requesting software
- [Nzbget](nzbget/) is a usenet downloader, written in C++ and designed with performance in mind to achieve maximum download speed by using very little system resources
- [Prowlarr](prowlarr/) ![smb][smb-shield] : Torrent Trackers and Usenet Indexers offering complete management ofSonarr, Radarr, Lidarr, and Readarr indexers with no per app setup required
- [Radarr](radarr/) ![smb][smb-shield] : A fork of Sonarr to work with movies like Couchpotato
- [Readarr](readarr/) ![smb][smb-shield] : Book Manager and Automation
- [Requestrr](requestrr/) : Chatbot used to simplify using services like Sonarr/Radarr/Ombi via the use of chat
- [Sonarr](sonarr/) ![smb][smb-shield] : Can monitor multiple RSS feeds for new episodes of your favorite shows and will grab, sort and rename them.

## &#10003; Organizers

- [Organizr](organizr/) : An HTPC/Homelab services organizer that is written in PHP

## &#10003; Security tools

- [Bitwarden](bitwarden/) : Open source password management solution
- [whoogle-search](whoogle/) : Self-hosted, ad-free, privacy-respecting metasearch engine

## &#10003; Torrent tools

- [Joal](joal/) ![ingress][ingress-shield] : An open source command line RatioMaster with WebUI.
- [Qbittorrent](qbittorrent/) ![smb][smb-shield] ![support][support-shield] ![ingress][ingress-shield] : Torrent manager with custom ui and many configurable options
- [Transmission](transmission/) ![smb][smb-shield] : The torrent client for Hass.io.

## &#10003; Web hosting

- [Grav](grav/) ![smb][smb-shield] : Fast, Simple, and Flexible, file-based Web-platform
- [Resioliosync by @tyjtyj](resiolosync/) ![smb][smb-shield]: Self-hosted file share and collaboration platform on the Web

[smb-shield]: https://img.shields.io/badge/SMB--green?style=plastic.svg
[sql-shield]: https://img.shields.io/badge/SQL-external-orange.svg
[privileged-shield]: https://img.shields.io/badge/privileged-required-orange.svg
[ingress-shield]: https://img.shields.io/badge/ingress--green.svg
[support-shield]: https://img.shields.io/badge/Support-thread-green.svg
[ram-shield]: https://img.shields.io/badge/RAM_min-4Gb-orange.svg
