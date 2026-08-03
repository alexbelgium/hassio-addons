
## 3.1.2.1076 (2025-11-22)
- Update to latest version from linuxserver/docker-resilio-sync (changelog : https://github.com/linuxserver/docker-resilio-sync/releases)
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 3.1.0.1073 (2025-07-18)
- Update to latest version from linuxserver/docker-resilio-sync (changelog : https://github.com/linuxserver/docker-resilio-sync/releases)
## 3.0.3.1065-7 (2025-06-25)
- Minor bugs fixed
## 3.0.3.1065-4 (2025-06-25)
- BREAKING CHANGE, please backup. Logic change : the config is not configurable anymore, and only stored in /config.

## 3.0.3.1065-3 (2025-06-24)

- Minor bugs fixed

## 3.0.3.1065-2 (2025-06-20)

- Minor bugs fixed

## 3.0.3.1065 (2025-03-15)

- Update to latest version from linuxserver/docker-resilio-sync (changelog : https://github.com/linuxserver/docker-resilio-sync/releases)

## 3.0.0.1409 (2024-08-24)

- Update to latest version from linuxserver/docker-resilio-sync (changelog : https://github.com/linuxserver/docker-resilio-sync/releases)

## 2.8.1.1390 (2024-06-08)

- Update to latest version from linuxserver/docker-resilio-sync (changelog : https://github.com/linuxserver/docker-resilio-sync/releases)

## 2.8.0.1389 (2024-05-11)

- Update to latest version from linuxserver/docker-resilio-sync (changelog : https://github.com/linuxserver/docker-resilio-sync/releases)
- Arm32v7 discontinued by linuxserver, latest working version pinned
- WARNING : update to supervisor 2022.11 before installing
- Ingress addition
- Set config and sync folders from options

## 2.7.3.1381 (2022-03-24)

- Update to latest version from linuxserver/docker-resilio-sync
- Add codenotary sign
- Cleanup: config base folder changed to /config/addons_config (thanks @bruvv)
- New standardized logic for Dockerfile build and packages installation
- Add local & smb mounts (see readme)
- Config changed from /config/resiliosync to /share/resiliosync_config

## 2.7.2.1375 (2021-06-30)

- Update to latest version from linuxserver/docker-resilio-sync
- :arrow_up: Initial release
