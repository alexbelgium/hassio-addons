### v1.0.0-4 (23-01-2024)
- Breaking change : port 9001 (mapped to 9090 by default) both for http and https

### v1.0.0-3 (22-01-2024)
- Minor bugs fixed

## v1.0.0 (22-01-2024)
- Switch of container to official version 1.0.0
- Adaptation of ports : please check addon options page
- Root user not anymore supported by upstream image, setting it to root (0:0) will revert to 1000:1000
- Default user of 1000:1000

## v1.0.0-RC1.1 (14-10-2023)
- Update to latest version from hay-kot/mealie
### v1.0.0-beta-5-4 (20-06-2023)
- Minor bugs fixed
### v1.0.0-beta-5-3 (07-06-2023)
- Minor bugs fixed
- Fix : avoid loop when upgrading from <1.0 versions https://github.com/alexbelgium/hassio-addons/issues/856

### v1.0.0-beta-5-2 (04-06-2023)
- Minor bugs fixed

### v1.0.0-beta-4 (07-05-2023)
- Minor bugs fixed

### v1.0.0-beta-3 (11-04-2023)
- Minor bugs fixed

## v1.0.0-beta-2 (11-04-2023)
- Fix : ssl (https://github.com/alexbelgium/hassio-addons/issues/782)
- Implemented healthcheck

## v1.0.0-beta-1 (07-01-2023)

- Update to latest version from hay-kot/mealie

## 1.0.1 (03-01-2023)

- Migrates data to cp -r /data/\* /config/addons_config/mealie_data/ to enable usage of new addons
- WARNING : update to supervisor 2022.11 before installing
- Optional passing of env variables by adding them in a config.yml file (see readme)
- Breaking change : amd64 updated to mealie 1.0
- You'll lose your database : first do a backup from within mealie, then restore after upgrading

## 1.0.0 (18-06-2022)

- Update to latest version from hay-kot/mealie

## 1.0.0.1 (26-05-2022)

- Update to latest version from hay-kot/mealie
- Add codenotary sign

## 0.5.6 (04-02-2022)

- Update to latest version from hay-kot/mealie

## 0.5.5 (04-02-2022)

- Update to latest version from hay-kot/mealie
- New standardized logic for Dockerfile build and packages installation

## 0.5.4 (03-12-2021)

- Update to latest version from hay-kot/mealie

## 0.5.3 (31-10-2021)

- Update to latest version from hay-kot/mealie
- Added ssl option

## 0.5.2 (26-07-2021)

- Update to latest version from hay-kot/mealie
- :arrow_up: Initial release
