
## v3.10.2 (2026-02-07)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v3.10.1 (2026-02-04)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)
## v3.9.2-5 (2026-01-09)
- Minor bugs fixed
## v3.9.2-4 (2026-01-09)
- Minor bugs fixed
## v3.9.2-3 (2026-01-07)
- Minor bugs fixed
## v3.9.2-2 (2026-01-07)
- Minor bugs fixed

## v3.9.2 (2026-01-03)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)
## v3.8.0-2 (2025-12-29)
- Minor bugs fixed

## v3.8.0 (2025-12-20)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)
## v3.6.1-5 (2025-12-12)
- Minor bugs fixed
## v3.6.1-4 (2025-12-12)
- Minor bugs fixed
## v3.6.1-3 (2025-12-12)
- Minor bugs fixed
## v3.6.1-2 (2025-12-08)
- Allow to start with sign up disabled

## v3.6.1 (2025-12-06)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)
## v3.5.0-2 (2025-12-06)
- Allow configuring Gunicorn's `--forwarded-allow-ips` value to support OIDC behind reverse proxies
- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

## v3.5.0 (2025-11-15)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## "v3.4.0" (2025-11-01)
- Minor bugs fixed

## v3.4.0 (2025-11-01)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v3.3.2 (2025-10-11)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v3.3.1 (2025-10-04)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)
## v3.2.1-2 (2025-09-27)
- Send discovery message to Home Assistant

## v3.2.1 (2025-09-20)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v3.1.2 (2025-08-30)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v3.1.1 (2025-08-23)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)
## v3.0.2-3 (2025-08-05)
- Prevent nginx from rewriting JSON responses to resolve recipe import errors

## v3.0.2-2 (2025-07-25)
- Minor bugs fixed

## v3.0.2 (2025-07-25)
- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)
## v3.0.1-6 (2025-07-18)
- Define NUXT_APP_BASE_URL as /mealie/

## v3.0.1-5 (2025-07-15)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)
- Fix ingress

## v3.0.0 (2025-07-12)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v2.8.0-24 (2025-07-08)

- Fix variables export in config.yaml : https://github.com/alexbelgium/hassio-addons/issues/1933

## v2.8.0 (2025-03-22)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v2.7.1-6 (2025-03-02)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v2.6.0 (2025-02-08)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v2.5.0-3 (2025-02-01)

- Minor bugs fixed

## v2.5.0 (2025-01-25)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v2.4.2-3 (2025-01-09)

- Minor bugs fixed

## v2.4.2-2 (2025-01-08)

- Minor bugs fixed

## v2.4.1-2 (2024-12-21)

- Minor bugs fixed

## v2.4.1 (2024-12-21)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)
- Add discovery to Mealie config (Thanks @andrew-codechimp)

## v2.3.0 (2024-11-30)

- Update to latest version from mealie-recipes/mealie (changelog : https://github.com/mealie-recipes/mealie/releases)

## v2.2.0 (2024-11-16)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v2.1.0-2 (2024-11-03)

- Addition of ingress, first try

## v2.1.0 (2024-11-02)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v2.0-beta5 (2024-10-15)

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

## v2.0-beta (2024-10-10)

- Switched to v2.0 beta, should hopefully solve everyone's issues!

## v1.12.0-3 (2024-09-22)

- Another version with 1.12 to try to solve issues with config not recognized

## v1.12.0-2 (2024-08-25)

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

## v1.12.0 (2024-08-24)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.11.0 (2024-08-03)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.10.2 (2024-07-06)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.9.0 (2024-06-22)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.8.0 (2024-06-08)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.7.0 (2024-05-25)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.6.0 (2024-05-11)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.5.1-2 (2024-05-01)

- Minor bugs fixed

## v1.5.1 (2024-04-20)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.4.0 (2024-04-06)

- Update to latest version from hay-kot/mealie (changelog : https://github.com/hay-kot/mealie/releases)

## v1.3.2 (2024-03-16)

- Update to latest version from hay-kot/mealie

## v1.3.1 (2024-03-09)

- Update to latest version from hay-kot/mealie

## v1.2.0 (2024-02-17)

- Update to latest version from hay-kot/mealie

## v1.1.1 (2024-02-03)

- Update to latest version from hay-kot/mealie

## v1.0.0-11 (2024-01-30)

- Fix : incorrect redirect https://github.com/alexbelgium/hassio-addons/issues/1210

## v1.0.0-10 (2024-01-26)

- Fix : .secret permissions denied by allowing again 0 as default user

## v1.0.0-8 (2024-01-24)

- Minor bugs fixed

## v1.0.0-7 (2024-01-24)

- Feat : exposed DATA_DIR in options to set a custom path

## v1.0.0-5 (2024-01-23)

- Fix : avoid spamming of "GET /api/app/about"

## v1.0.0-4 (2024-01-23)

- Breaking change : port 9001 (mapped to 9090 by default) both for http and https

## v1.0.0-3 (2024-01-22)

- Minor bugs fixed

## v1.0.0 (2024-01-22)

- Switch of container to official version 1.0.0
- Adaptation of ports : please check addon options page
- Root user not anymore supported by upstream image, setting it to root (0:0) will revert to 1000:1000
- Default user of 1000:1000

## v1.0.0-RC1.1 (2023-10-14)

- Update to latest version from hay-kot/mealie

## v1.0.0-beta-5-4 (2023-06-20)

- Minor bugs fixed

## v1.0.0-beta-5-3 (2023-06-07)

- Minor bugs fixed
- Fix : avoid loop when upgrading from <1.0 versions https://github.com/alexbelgium/hassio-addons/issues/856

## v1.0.0-beta-5-2 (2023-06-04)

- Minor bugs fixed

## v1.0.0-beta-4 (2023-05-07)

- Minor bugs fixed

## v1.0.0-beta-3 (2023-04-11)

- Minor bugs fixed

## v1.0.0-beta-2 (2023-04-11)

- Fix : ssl (https://github.com/alexbelgium/hassio-addons/issues/782)
- Implemented healthcheck

## v1.0.0-beta-1 (2023-01-07)

- Update to latest version from hay-kot/mealie

## 1.0.1 (2023-01-03)

- Migrates data to cp -r /data/\* /config/ to enable usage of new addons
- WARNING : update to supervisor 2022.11 before installing
- Optional passing of env variables by adding them in a config.yml file (see readme)
- Breaking change : amd64 updated to mealie 1.0
- You'll lose your database : first do a backup from within mealie, then restore after upgrading

## 1.0.0 (2022-06-18)

- Update to latest version from hay-kot/mealie

## 1.0.0.1 (2022-05-26)

- Update to latest version from hay-kot/mealie
- Add codenotary sign

## 0.5.6 (2022-02-04)

- Update to latest version from hay-kot/mealie

## 0.5.5 (2022-02-04)

- Update to latest version from hay-kot/mealie
- New standardized logic for Dockerfile build and packages installation

## 0.5.4 (2021-12-03)

- Update to latest version from hay-kot/mealie

## 0.5.3 (2021-10-31)

- Update to latest version from hay-kot/mealie
- Added ssl option

## 0.5.2 (2021-07-26)

- Update to latest version from hay-kot/mealie
- :arrow_up: Initial release
