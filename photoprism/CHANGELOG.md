## ubuntu-2025-11-30-4 (26-02-2026)
- Minor bugs fixed
## ubuntu-2025-11-30-3 (2026-01-10)
- ⚠ MAJOR CHANGE : switch to the new config logic from homeassistant. Your configuration files will have migrated from /config/addons_config/photoprism to a folder only accessible from my Filebrowser addon called /addon_configs/xxx-photoprism. This avoids the addon to mess with your homeassistant configuration folder, and allows to backup the options. Migration of data should be automatic, but update any custom paths or permissions to avoid breakage. Please be sure to update all your links however ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/

## ubuntu-2025-11-30 (2025-11-30)
- Update to latest version from photoprism/photoprism

##  (2025-12-23)
- Update to latest version from photoprism/photoprism
## ubuntu-2025-11-30-2 (2025-12-06)
- Increase healthcheck interval to reduce background CPU usage

## ubuntu-2025-11-30 (2025-11-30)
- Update to latest version from photoprism/photoprism

## ubuntu-2025-11-27 (2025-11-27)
- Update to latest version from photoprism/photoprism
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## "ubuntu-2025-10-18" (2025-10-25)
- Minor bugs fixed

## ubuntu-2025-10-18 (2025-10-18)
- Update to latest version from photoprism/photoprism
## ubuntu-2025-07-07 (2025-07-07)

- Update to latest version from photoprism/photoprism

## ubuntu-2025-04-26 (2025-04-26)

- Update to latest version from photoprism/photoprism

## ubuntu-2025-04-25 (2025-04-25)

- Update to latest version from photoprism/photoprism

## ubuntu-2025-03-21 (2025-03-21)

- Update to latest version from photoprism/photoprism

## ubuntu-2025-02-28-8 (2025-03-02)

- Fix ssl error
- Update to latest version from photoprism/photoprism

## ubuntu-2024-09-15 (2024-09-15)

- Update to latest version from photoprism/photoprism

## ubuntu-2024-07-11 (2024-07-11)

- Update to latest version from photoprism/photoprism

## ubuntu-2024-05-31-3 (2024-06-10)

- Minor bugs fixed

## ubuntu-2024-05-31 (2024-05-31)

- Update to latest version from photoprism/photoprism

## ubuntu-2024-05-23 (2024-05-23)

- Update to latest version from photoprism/photoprism

## 240420-ef5f14bc4 (2024-05-18)

- Minor bugs fixed

## preview-ubuntu-2023-04-29-4 (2023-12-04)

- Allows non-admin users to use paperless from HA sidebar

## preview-ubuntu-2023-04-29 (2023-04-29)

- Update to latest version from photoprism/photoprism

## 231021 (2023-10-22)

- Update to latest version from photoprism/photoprism

## ubuntu-231011 (2023-10-17)

- Update to latest version from photoprism/photoprism

## ubuntu-230719-73fa7bbe8 (2023-07-25)

- Update to latest version from photoprism/photoprism

## ubuntu (2023-07-24)

- Update to latest version from photoprism/photoprism

## ubuntu (2023-06-10)

- Update to latest version from photoprism/photoprism
- Feat : cifsdomain added

## preview-9 (2023-05-07)

- Minor bugs fixed

## preview-8 (2023-04-24)

- Minor bugs fixed

## preview-7 (2023-04-24)

- Minor bugs fixed
- Allow environment to be available from command line

## Preview-6 (2023-04-15)

- Minor bugs fixed
- Implemented healthcheck
- Add message if ingress disabled

## Preview (2023-01-27)

- Switch build to preview
- Add "video": true
- Default PHOTOPRISM_DETECT_NSFW true
- Add sys_rawio

## 20220121 (2022-12-10)

- Update to latest version from photoprism/photoprism
- BREAKING CHANGE : url for direct access to be updated, check logs for url to use
- WARNING : update to supervisor 2022.11 before installing

## 20220121 (2022-09-01)

- Update to latest version from photoprism/photoprism

## 220730-jammy (2022-08-04)

- Update to latest version from photoprism/photoprism

## 220728-jammy (2022-07-30)

- Update to latest version from photoprism/photoprism

## 220629-jammy (2022-06-30)

- Update to latest version from photoprism/photoprism

## 220617-jammy (2022-06-18)

- Update to latest version from photoprism/photoprism

## 220614-jammy (2022-06-16)

- Update to latest version from photoprism/photoprism

## 220528-jammy (2022-05-31)

- Update to latest version from photoprism/photoprism

## 220524-bookworm (2022-05-26)

- Update to latest version from photoprism/photoprism
- Feat: ingress implementation

## 220517-jammy (2022-05-19)

- Update to latest version from photoprism/photoprism
- Implementation of ssl
- Add codenotary sign

## 220302-impish (2022-03-03)

- Update to latest version from photoprism/photoprism
- CUSTOM_OPTIONS deprecated : use config.yaml (see Readme)
- Any ENV variables can be set by config.yaml (see Readme)

## 20220121 (2022-01-21)

- Update to latest version from photoprism/photoprism

## 20220118 (2022-01-18)

- Update to latest version from photoprism/photoprism

## 20220107 (2022-01-07)

- Update to latest version from photoprism/photoprism

## 20211215 (2021-12-16)

- Update to latest version from photoprism/photoprism

## 20211210 (2021-12-12)

- Update to latest version from photoprism/photoprism
- New standardized logic for Dockerfile build and packages installation
- Allow mounting local drives by label. Just pust the label instead of sda1 for example
- Allow mounting of devices up to sdg2
- SMB : accepts several disks separated by commas mounted in /mnt/$sharename

## 210217-49039368 (2021-09-29)

- Update to latest version from photoprism/photoprism
- Allow mounting smb and local disks
- Allow custom paths from options
- Allow any custom photoprism flags
- Initial release
