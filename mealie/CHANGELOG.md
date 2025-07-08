- Fix variables export in config.yaml : https://github.com/alexbelgium/hassio-addons/issues/1933

## v2.8.0 (22-03-2025)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v2.7.1-6 (02-03-2025)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v2.6.0 (08-02-2025)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v2.5.0-3 (01-02-2025)

- Minor bugs fixed

## v2.5.0 (25-01-2025)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v2.4.2-3 (09-01-2025)

- Minor bugs fixed

## v2.4.2-2 (08-01-2025)

- Minor bugs fixed

## v2.4.1-2 (21-12-2024)

- Minor bugs fixed

## v2.4.1 (21-12-2024)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)
- Add discovery to Mealie config (Thanks @andrew-codechimp)

## v2.3.0 (30-11-2024)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v2.2.0 (16-11-2024)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v2.1.0-2 (03-11-2024)

- Addition of ingress, first try

## v2.1.0 (02-11-2024)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v2.0-beta5 (15-10-2024)

- Applied new homeassistant config logic, which will allow in the future all Mealie data to be backuped with the addon. All data (+ config) is moved to /addon_configs/db21ed7f_mealie ; the initial data currently in /homeassistant/addons_config/mealie_data and config in /homeassistant/addons_config/mealie will not be moved but a "migrated" file will be added to those folders to show that migration occured. From now on, only data in /addon_configs/db21ed7f_mealie will be used.
- If it doesn't load, there was perhaps an issue with the migration with a previous version. The solution : go in the Filebrowser addon, open the path /config/db21ed7f_mealie, move everything there in a new folder named old. Go then in the path /homeassistant/addons_config/mealie_data and remove the file named migrated. Restart the addon, and the migration will occur again

- Logic change in terms of files :

  Previous logic :

  - Paths within container :
    - Data: /config/addons_config/mealie_data
    - Injector script: /config/addons_autoscripts/mealie.sh
    - Env file : /config/addons_autoscripts/mealie/config.yaml
  - Paths from HA (for example with Filebrowser) :
    - Data: /homeassistant/addons_config/mealie_data
    - Injector script: /homeassistant/addons_autoscripts/mealie.sh
    - Env file : /homeassistant/addons_autoscripts/mealie/config.yaml
  - Addon option : DATA_DIR="/config/addons_config/mealie_data"

  New logic :

  - Paths within container :
    - Data: /config
    - Injector script: /config/mealie.sh
    - Env file : /config/config.yaml
  - Paths from HA (for example with Filebrowser) :
    - Data: /addon_configs/db21ed7f_mealie
    - Injector script: /addon_configs/db21ed7f_mealie/mealie.sh
    - Env file : /addon_configs/db21ed7f_mealie/config.yaml
  - Previous files backup (will not be used anymore thanks to the "Migrated file" that is now in their folder) :
    - Data: /homeassistant/addons_config/mealie_data
    - Injector script: /homeassistant/addons_autoscripts/mealie.sh
    - Env file : /homeassistant/addons_autoscripts/mealie/config.yaml
  - Addon option : DATA_DIR="/config"

## v2.0-beta (10-10-2024)

- Switched to v2.0 beta, should hopefully solve everyone's issues!

## v1.12.0-3 (22-09-2024)

- Another version with 1.12 to try to solve issues with config not recognized

## v1.12.0-2 (25-08-2024)

- BACKUP BEFORE UPDATING !!!
- WARNING : version 1.12 erroneously updated to 2.0. Your database could become corrupted if you update from 1.12. You need to restore your homeassistant config directory before updating to this version Alas there is no easy solution to move back from Mealie 2.0 to 1.2.

- If you had a backup from mealie :
  - make a clean install (rename folder /homeassistant/addons_config/mealie_data to mealie_data.bak)
  - restart the latest version of the addon (which will fully reset) and restore your backup
- If you have a backup from homeassistant of the /config folder :
  - you should rename the folder /homeassistant/addons_config/mealie_data to mealie_data.bak
  - extract your backup
  - Copy the /homeassistant/addons_config/mealie_data folder from your backup to the same path in homeassistant
- Wait for the addon to move back to 2.0 to use your database that was upgraded...

If you have neither, alas Mealie has no way to way back from the upgrade that occurred... For info, I've improved the system to make sure that the data is backuped in the future (this function did not exist when I created the addon) but this doesn't help for this specific issue.

## v1.12.0 (24-08-2024)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.11.0 (03-08-2024)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.10.2 (06-07-2024)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.9.0 (22-06-2024)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.8.0 (08-06-2024)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.7.0 (25-05-2024)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.6.0 (11-05-2024)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.5.1-2 (01-05-2024)

- Minor bugs fixed

## v1.5.1 (20-04-2024)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.4.0 (06-04-2024)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.3.2 (16-03-2024)

- Update to latest version from hay-kot/mealie

## v1.3.1 (09-03-2024)

- Update to latest version from hay-kot/mealie

## v1.2.0 (17-02-2024)

- Update to latest version from hay-kot/mealie

## v1.1.1 (03-02-2024)

- Update to latest version from hay-kot/mealie

## v1.0.0-11 (30-01-2024)

- Fix : incorrect redirect https://github.com/alexbelgium/hassio-addons/issues/1210

## v1.0.0-10 (26-01-2024)

- Fix : .secret permissions denied by allowing again 0 as default user

## v1.0.0-8 (24-01-2024)

- Minor bugs fixed

## v1.0.0-7 (24-01-2024)

- Feat : exposed DATA_DIR in options to set a custom path

## v1.0.0-5 (23-01-2024)

- Fix : avoid spamming of "GET /api/app/about"

## v1.0.0-4 (23-01-2024)

- Breaking change : port 9001 (mapped to 9090 by default) both for http and https

## v1.0.0-3 (22-01-2024)

- Minor bugs fixed

## v1.0.0 (22-01-2024)

- Switch of container to official version 1.0.0
- Adaptation of ports : please check addon options page
- Root user not anymore supported by upstream image, setting it to root (0:0) will revert to 1000:1000
- Default user of 1000:1000

## v1.0.0-RC1.1 (14-10-2023)

- Update to latest version from hay-kot/mealie

## v1.0.0-beta-5-4 (20-06-2023)

- Minor bugs fixed

## v1.0.0-beta-5-3 (07-06-2023)

- Minor bugs fixed
- Fix : avoid loop when upgrading from <1.0 versions https://github.com/alexbelgium/hassio-addons/issues/856

## v1.0.0-beta-5-2 (04-06-2023)

- Minor bugs fixed

## v1.0.0-beta-4 (07-05-2023)

- Minor bugs fixed

## v1.0.0-beta-3 (11-04-2023)

- Minor bugs fixed

## v1.0.0-beta-2 (11-04-2023)

- Fix : ssl (https://github.com/alexbelgium/hassio-addons/issues/782)
- Implemented healthcheck

## v1.0.0-beta-1 (07-01-2023)

- Update to latest version from hay-kot/mealie

## 1.0.1 (03-01-2023)

- Migrates data to cp -r /data/\* /config/ to enable usage of new addons
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
