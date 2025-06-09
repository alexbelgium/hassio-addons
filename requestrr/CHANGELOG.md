## 2.1.8 (07-06-2025)

- Update to latest version from thomst08/requestrr (changelog : https://github.com/thomst08/requestrr/releases)

## 2.1.7 (21-09-2024)

- Update to latest version from thomst08/requestrr (changelog : https://github.com/thomst08/requestrr/releases)

## 2.1.6 (27-03-2024)

- ⚠ MAJOR CHANGE : switch to the new config logic from homeassistant. Your configuration files will have migrated from /config/hassio_addons/requestrr in a folder only accessible from my Filebrowser addon called /addon_configs/db21ed7f_requestrr. This avoids the addon to mess with your homeassistant configuration folder, and allows to backup the options. Migration of data, custom configs, and custom scripts should be automatic. Please be sure to update all your links however ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/
- WARNING : update to supervisor 2022.11 before installing

## 2.1.2 (11-04-2022)

- Update to latest version from linuxserver/docker-requestrr
- Add codenotary sign
- New standardized logic for Dockerfile build and packages installation

## 2.1.1 (15-10-2021)

- Update to latest version from linuxserver/docker-requestrr
- Initial release
