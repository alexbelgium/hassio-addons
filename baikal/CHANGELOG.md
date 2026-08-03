- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

## 0.10.1-hafix4 (2025-11-18)
- Minor bugs fixed
## 0.10.1-hafix3 (2025-11-18)
- Added support for configuring extra environment variables via the `env_vars` option alongside config.yaml.

## 0.10.1-hafix2 (2025-08-01)
- Minor bugs fixed

## 0.10.1+hafix (2025-04-26)
- Update to latest version from ckulka/baikal-docker (changelog : https://github.com/ckulka/baikal-docker/releases)
## 0.10.1-2 (2024-11-23)
- Minor bugs fixed

## 0.10.1 (2024-11-23)
- Update to latest version from ckulka/baikal-docker (changelog : https://github.com/ckulka/baikal-docker/releases)
## 0.9.5_updated (2024-08-06)
- Minor bugs fixed

## 0.9.5 (2024-04-27)
- Update to latest version from ckulka/baikal-docker (changelog : https://github.com/ckulka/baikal-docker/releases)
## 0.9.4-3 (2024-04-26)
- ⚠ MAJOR CHANGE : switch to the new config logic from homeassistant. Your configuration files will have migrated from /config/hassio_addons/baikal to a folder only accessible from my Filebrowser addon called /addon_configs/something-baikal. This avoids the addon to mess with your homeassistant configuration folder, and allows to backup the options. Migration of data, custom configs, and custom scripts should be automatic. Please be sure to update all your links however ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/

## 0.9.4-2 (2024-01-14)

- Minor bugs fixed

## 0.9.4+msmtpfix (2023-12-30)

- Update to latest version from ckulka/baikal-docker

## 0.9.4 (2023-12-23)

- Update to latest version from ckulka/baikal-docker

## 0.9.3+msmtp (2023-11-04)

- Update to latest version from ckulka/baikal-docker
- Implemented healthcheck

## 0.9.3 (2022-12-13)

- Update to latest version from ckulka/baikal-docker
- WARNING : update to supervisor 2022.11 before installing

## 0.9.2

- First version
