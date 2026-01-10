
## 6.0.4.10291-1 (2026-01-08)
- ⚠ MAJOR CHANGE : switch to the new config logic from homeassistant. Your configuration files will have migrated from /config/addons_config/radarr to a folder only accessible from my Filebrowser addon called /addon_configs/xxx-radarr_nas. This avoids the addon to mess with your homeassistant configuration folder, and allows to backup the options. Migration of data should be automatic. Please be sure to update all your links however ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/

## 6.0.4.10291 (2025-11-22)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)
- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## "5.28.0.10274" (2025-10-18)
- Minor bugs fixed

## 5.28.0.10274 (2025-10-18)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.27.5.10198 (2025-09-06)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)
## 5.26.2.10099 (2025-06-21)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.25.0.10024 (2025-05-31)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.23.3.9987 (2025-05-24)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.22.4.9896 (2025-04-26)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.21.1.9799 (2025-03-29)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.20.2.9777 (2025-03-22)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.19.3.9730 (2025-03-01)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.18.4.9674 (2025-02-08)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.17.2.9580 (2025-01-11)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.16.3.9541 (2024-12-21)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.15.1.9463 (2024-11-23)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.14.0.9383 (2024-11-02)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.12.2.9335 (2024-10-19)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.11.0.9244 (2024-09-28)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.9.1.9070 (2024-08-24)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.8.3.8933 (2024-07-27)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.7.0.8882 (2024-06-22)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.6.0.8846 (2024-05-18)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.4.6.8723-5 (2024-04-22)

- Fix : not starting

## 5.4.6.8723-4 (2024-04-21)

- BREAKING CHANGE : ingress_disabled option removed. Instead, a new option connection_mode is added. It has 3 modes : ingress_noauth (default, disables authentification to allow a seamless ingress integration), noingress_auth (disables ingress to allow a simpler external url, enables authentification), ingress_auth (enables both ingress and authentification). Thanks @Ni3kjm !

## 5.4.6.8723 (2024-04-20)

- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.3.6.8612 (2024-02-24)

- Update to latest version from linuxserver/docker-radarr
- There is now an official addon in the community repository, you should migrate to it ! However it does not support ingress ;)

## 5.2.6.8376 (2023-12-30)

- Update to latest version from linuxserver/docker-radarr

## 5.1.3.8246-4 (2023-12-02)

- Minor bugs fixed
- Send crond messages to addon logs

## 5.1.3.8246 (2023-11-18)

- Update to latest version from linuxserver/docker-radarr

## 5.0.3.8127-2 (2023-11-01)

- Minor bugs fixed
- Fix : disable authentification when using ingress

## 5.0.3.8127 (2023-10-14)

- Update to latest version from linuxserver/docker-radarr

## 4.7.5.7809-2 (2023-09-27)

- Minor bugs fixed

## 4.7.5.7809 (2023-08-19)

- Update to latest version from linuxserver/docker-radarr
- armv7 discontinued by lsio

## 4.6.4.7568 (2023-07-08)

- Update to latest version from linuxserver/docker-radarr

## 4.5.2.7388 (2023-06-03)

- Update to latest version from linuxserver/docker-radarr

## 4.4.4.7068-2 (2023-05-12)

- Minor bugs fixed

## 4.4.4.7068 (2023-04-21)

- Update to latest version from linuxserver/docker-radarr

## 4.3.2.6857-21 (2023-03-17)

- Minor bugs fixed
- Solve signalr error https://github.com/alexbelgium/hassio-addons/issues/757
- Implemented healthcheck
- Add ingress_disabled option
- Ingress addition
- BaseUrl definition to "radarr"

## 4.3.2.6857 (2023-01-07)

- Update to latest version from linuxserver/docker-radarr
- WARNING : update to supervisor 2022.11 before installing

## 4.2.4.6635 (2022-09-27)

- Update to latest version from linuxserver/docker-radarr

## 4.1.0.6175 (2022-04-16)

- Update to latest version from linuxserver/docker-radarr
- Add codenotary sign

## 4.0.5.5981 (2022-03-06)

- Update to latest version from linuxserver/docker-radarr

## 4.0.4.5922 (2022-01-31)

- Update to latest version from linuxserver/docker-radarr

## 3.2.2.5080-7 (2022-01-03)

- Cleanup: config base folder changed to /config/addons_config (thanks @bruvv)
- New standardized logic for Dockerfile build and packages installation
- Allow mounting local drives by label. Just pust the label instead of sda1 for example
- SMB : accepts several disks separated by commas mounted in /mnt/$sharename
- Breaking changes : multiple network disks must be separated by a "," and they are mounted to a folder with the name of the external share.

## 3.2.2.5080 (2021-06-04)

- Update to latest version from linuxserver/docker-radarr

## 3.2.1.5070 (2021-05-28)

- Update to latest version from linuxserver/docker-radarr

## 3.2.0.5048 (2021-05-19)

- Update to latest version from linuxserver/docker-radarr

## 3.1.1.4954 (2021-05-05)

- Update to latest version from linuxserver/docker-radarr

## 3.0.2.4552

- Update to latest version from linuxserver/docker-radarr
- Enables PUID/PGID options
