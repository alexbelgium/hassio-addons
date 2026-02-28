
## 1.5.6 (2026-02-28)
- Update to latest version from linuxserver/docker-bazarr (changelog : https://github.com/linuxserver/docker-bazarr/releases)

## 1.5.5 (2026-02-04)
- Update to latest version from linuxserver/docker-bazarr (changelog : https://github.com/linuxserver/docker-bazarr/releases)

## 1.5.4-1 (2026-01-08)
- ⚠ MAJOR CHANGE : switch to the new config logic from homeassistant. Your configuration files will have migrated from /config/addons_config/bazarr to a folder only accessible from my Filebrowser addon called /addon_configs/xxx-bazarr. This avoids the addon to mess with your homeassistant configuration folder, and allows to backup the options. Migration of data should be automatic. Please be sure to update all your links however ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/

## 1.5.4 (2026-01-08)
- Update to latest version from linuxserver/docker-bazarr (changelog : https://github.com/linuxserver/docker-bazarr/releases)
- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 1.5.3 (2025-09-27)
- Update to latest version from linuxserver/docker-bazarr (changelog : https://github.com/linuxserver/docker-bazarr/releases)

## 1.5.2 (2025-05-17)
- Update to latest version from linuxserver/docker-bazarr (changelog : https://github.com/linuxserver/docker-bazarr/releases)

## 1.5.1 (2025-01-04)
- Update to latest version from linuxserver/docker-bazarr (changelog : https://github.com/linuxserver/docker-bazarr/releases)

## 1.5.0 (2024-12-28)
- Update to latest version from linuxserver/docker-bazarr (changelog : https://github.com/linuxserver/docker-bazarr/releases)

## 1.4.5 (2024-10-05)
- Update to latest version from linuxserver/docker-bazarr (changelog : https://github.com/linuxserver/docker-bazarr/releases)

## 1.4.4 (2024-09-21)
- Update to latest version from linuxserver/docker-bazarr (changelog : https://github.com/linuxserver/docker-bazarr/releases)

## 1.4.3 (2024-06-08)
- Update to latest version from linuxserver/docker-bazarr (changelog : https://github.com/linuxserver/docker-bazarr/releases)

## 1.4.2 (2024-02-24)

- Update to latest version from linuxserver/docker-bazarr

## 1.4.1 (2024-02-10)

- Update to latest version from linuxserver/docker-bazarr
## 1.4.0-2 (2023-12-04)

- Minor bugs fixed

## 1.4.0 (2023-12-02)

- Update to latest version from linuxserver/docker-bazarr

## 1.3.1 (2023-10-20)

- Update to latest version from linuxserver/docker-bazarr

## 1.3.0 (2023-09-16)

- Update to latest version from linuxserver/docker-bazarr

## 1.2.4 (2023-07-22)

- Update to latest version from linuxserver/docker-bazarr
## 1.2.3-2 (2023-07-16)

- Minor bugs fixed
- Armv7 discontinued, pinned to latest working

## 1.2.3 (2023-07-15)

- Update to latest version from linuxserver/docker-bazarr

## 1.2.2 (2023-07-01)

- Update to latest version from linuxserver/docker-bazarr

## 1.2.1 (2023-05-06)

- Update to latest version from linuxserver/docker-bazarr
## 1.2.0-1 (2023-04-21)

- Minor bugs fixed
- Implemented healthcheck

## 1.2.0 (2023-03-04)

- Update to latest version from linuxserver/docker-bazarr

## 1.1.4 (2023-01-07)

- Update to latest version from linuxserver/docker-bazarr

## 1.1.3 (2022-12-06)

- Update to latest version from linuxserver/docker-bazarr
- WARNING : update to supervisor 2022.11 before installing

## 1.1.2 (2022-10-18)

- Update to latest version from linuxserver/docker-bazarr
- New feature : localdisks mounting added

## 1.1.1 (2022-09-01)

- Update to latest version from linuxserver/docker-bazarr

## 1.1.0 (2022-07-05)

- Update to latest version from linuxserver/docker-bazarr

## 1.0.4 (2022-05-01)

- Update to latest version from linuxserver/docker-bazarr

## 1.0.3 (2022-04-27)

- Update to latest version from linuxserver/docker-bazarr
- Add codenotary sign

## 1.0.3 (2022-02-27)

- Update to latest version from linuxserver/docker-bazarr

## 1.0.2 (2022-01-04)

- Update to latest version from linuxserver/docker-bazarr

## v1.0.2-ls140

- Fixed local config
- updated to v1.0.2-ls140

## 1.0.2 (2022-01-01)

- Update to latest version from linuxserver/docker-bazarr
- Cleanup: config base folder changed to /config/addons_config (thanks @bruvv)
- New standardized logic for Dockerfile build and packages installation

## 1.0.1 (2021-11-20)

- Update to latest version from linuxserver/docker-bazarr
- Allow mounting local drives by label. Just pust the label instead of sda1 for example
- SMB : accepts several disks separated by commas mounted in /mnt/$sharename

## 1.0.0 (2021-10-13)

- Update to latest version from linuxserver/docker-bazarr

## 0.9.9 (2021-09-11)

- Update to latest version from linuxserver/docker-bazarr

## 0.9.8 (2021-09-02)

- Update to latest version from linuxserver/docker-bazarr

## 0.9.7 (2021-08-14)

- Update to latest version from linuxserver/docker-bazarr

## 0.9.6 (2021-08-07)

- Update to latest version from linuxserver/docker-bazarr

## 2.6.2 (2021-08-07)

- Update to latest version from alexbelgium/portainer

## 0.9.6 (2021-07-21)

- Update to latest version from linuxserver/docker-bazarr
- Enable smb mounts

## 0.9.5 (2021-05-09)

- Update to latest version from linuxserver/docker-bazarr

## 3.0.2.4552

- Update to latest version from linuxserver/docker-bazarr
- Enables PUID/PGID options
