- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 2.2.4-2 (2025-08-09)
- Minor bugs fixed

## 2.2.4 (2025-08-09)
- Update to latest version from nathanvaughn/webtrees-docker (changelog : https://github.com/nathanvaughn/webtrees-docker/releases)

## 2.2.3 (2025-08-01)
- Update to latest version from nathanvaughn/webtrees-docker (changelog : https://github.com/nathanvaughn/webtrees-docker/releases)
## 2.2.1-4 (2025-01-06)
- BREAKING CHANGE : please be sure to backup your system (HA, and backup from webtrees UI) before updating
  - Major code refactor : there is no automatic first user creation, it now opens the wizard and provides additional instructions in the addon log (detecting if it is a first launch or not)
  - Data location change : the data location is now configurable through an option. It will now by default move files to /config/data ; accessible by an external editor through /addon_configs/xxx-webtrees/data. I haven't tested it with all configurations (including mariadb) so be careful before updating! However, it will be much more robust & reliable in the future. And should allow to move data storage location
  - Database logic change : database selection (sqlite, mysql, psql) is done through the initial startup wizard. If you want to change it, you need to modify manually the config.php.ini file in /config/data (mapped to /addon_configs/xxx-webtrees/data when accessing using a third party tool)

## 2.2.1-2 (2025-01-02)
- Minor bugs fixed

## 2.2.1 (2024-12-07)
- Update to latest version from nathanvaughn/webtrees-docker (changelog : https://github.com/nathanvaughn/webtrees-docker/releases)

## 2.2.0 (2024-11-30)
- Update to latest version from nathanvaughn/webtrees-docker (changelog : https://github.com/nathanvaughn/webtrees-docker/releases)

## 2.1.20 (2024-04-13)
- Update to latest version from nathanvaughn/webtrees-docker (changelog : https://github.com/nathanvaughn/webtrees-docker/releases)

## 2.1.19 (2024-03-23)
- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.18 (2023-10-20)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.17 (2023-07-15)

- Update to latest version from nathanvaughn/webtrees-docker
- Feat : cifsdomain added

## 2.1.16 (2023-01-21)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.15 (2022-12-25)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.14 (2022-12-25)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.12 (2022-12-10)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.11 (2022-12-06)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.9 (2022-12-01)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.8 (2022-11-28)

- Update to latest version from nathanvaughn/webtrees-docker
- WARNING : update to supervisor 2022.11 before installing

## v2.1.7 (2022-08-04)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.6 (2022-06-23)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.5 (2022-06-06)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.4 (2022-05-24)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.2 (2022-05-06)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.1 (2022-04-29)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.0 (2022-04-22)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.0-beta.2 (2022-04-05)

- Update to latest version from nathanvaughn/webtrees-docker
- Add codenotary sign

## 2.1.0-beta.1 (2022-03-19)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.0-alpha.2 (2022-02-04)

- Update to latest version from nathanvaughn/webtrees-docker
- Allow mounting smb and local drives for data storage
- Allow Mariadb addon autodiscovery as database

## 2.1.0-alpha.1 (2021-12-28)

- Switch to 2.1
- Update to latest version from nathanvaughn/webtrees-docker
- New standardized logic for Dockerfile build and packages installation

## 2.0.19 (2021-12-07)

- Update to latest version from nathanvaughn/webtrees-docker
- allow !secrets in config.yaml (see Home Assistant documentation)
- Add config.yaml configurable options (see readme)
