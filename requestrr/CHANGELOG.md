- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 2.1.9 (2025-09-20)
- Update to latest version from thomst08/requestrr (changelog : https://github.com/thomst08/requestrr/releases)

## 2.1.8 (2025-06-07)
- Update to latest version from thomst08/requestrr (changelog : https://github.com/thomst08/requestrr/releases)

## 2.1.7 (2024-09-21)
- Update to latest version from thomst08/requestrr (changelog : https://github.com/thomst08/requestrr/releases)
## 2.1.6 (2024-03-27)
- ⚠ MAJOR CHANGE : switch to the new config logic from homeassistant. Your configuration files will have migrated from /config/hassio_addons/requestrr in a folder only accessible from my Filebrowser addon called /addon_configs/db21ed7f_requestrr. This avoids the addon to mess with your homeassistant configuration folder, and allows to backup the options. Migration of data, custom configs, and custom scripts should be automatic. Please be sure to update all your links however ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/
- WARNING : update to supervisor 2022.11 before installing

## 2.1.2 (2022-04-11)

- Update to latest version from linuxserver/docker-requestrr
- Add codenotary sign
- New standardized logic for Dockerfile build and packages installation

## 2.1.1 (2021-10-15)

- Update to latest version from linuxserver/docker-requestrr
- Initial release
