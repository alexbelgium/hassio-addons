## 2.2.1-4 (06-01-2025)

- BREAKING CHANGE : please be sure to backup your system (HA, and backup from webtrees UI) before updating
  - Major code refactor : there is no automatic first user creation, it now opens the wizard and provides additional instructions in the addon log (detecting if it is a first launch or not)
  - Data location change : the data location is now configurable through an option. It will now by default move files to /config/data ; accessible by an external editor through /addon_configs/xxx-webtrees/data. I haven't tested it with all configurations (including mariadb) so be careful before updating! However, it will be much more robust & reliable in the future. And should allow to move data storage location
  - Database logic change : database selection (sqlite, mysql, psql) is done through the initial startup wizard. If you want to change it, you need to modify manually the config.php.ini file in /config/data (mapped to /addon_configs/xxx-webtrees/data when accessing using a third party tool)

## 2.2.1-2 (02-01-2025)

- Minor bugs fixed

## 2.2.1 (07-12-2024)

- Update to latest version from nathanvaughn/webtrees-docker (changelog : https://github.com/nathanvaughn/webtrees-docker/releases)

## 2.2.0 (30-11-2024)

- Update to latest version from nathanvaughn/webtrees-docker (changelog : https://github.com/nathanvaughn/webtrees-docker/releases)

## 2.1.20 (13-04-2024)

- Update to latest version from nathanvaughn/webtrees-docker (changelog : https://github.com/nathanvaughn/webtrees-docker/releases)

## 2.1.19 (23-03-2024)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.18 (20-10-2023)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.17 (15-07-2023)

- Update to latest version from nathanvaughn/webtrees-docker
- Feat : cifsdomain added

## 2.1.16 (21-01-2023)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.15 (25-12-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.14 (25-12-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.12 (10-12-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.11 (06-12-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.9 (01-12-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.8 (28-11-2022)

- Update to latest version from nathanvaughn/webtrees-docker
- WARNING : update to supervisor 2022.11 before installing

## v2.1.7 (04-08-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.6 (23-06-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.5 (06-06-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.4 (24-05-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.2 (06-05-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.1 (29-04-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## v2.1.0 (22-04-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.0-beta.2 (05-04-2022)

- Update to latest version from nathanvaughn/webtrees-docker
- Add codenotary sign

## 2.1.0-beta.1 (19-03-2022)

- Update to latest version from nathanvaughn/webtrees-docker

## 2.1.0-alpha.2 (04-02-2022)

- Update to latest version from nathanvaughn/webtrees-docker
- Allow mounting smb and local drives for data storage
- Allow Mariadb addon autodiscovery as database

## 2.1.0-alpha.1 (28-12-2021)

- Switch to 2.1
- Update to latest version from nathanvaughn/webtrees-docker
- New standardized logic for Dockerfile build and packages installation

## 2.0.19 (07-12-2021)

- Update to latest version from nathanvaughn/webtrees-docker
- allow !secrets in config.yaml (see Home Assistant documentation)
- Add config.yaml configurable options (see readme)
