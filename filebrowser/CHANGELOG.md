## 2.42.0 (28-07-2025)
- Minor bugs fixed
## 2.41.0-5 (25-07-2025)
- Minor bugs fixed
## 2.41.0-4 (25-07-2025)
- Minor bugs fixed
## 2.41.0-3 (25-07-2025)
- Minor bugs fixed
## 2.41.0-2 (25-07-2025)
- Minor bugs fixed
## 2.41.0 (25-07-2025)
- Minor bugs fixed

## 2.40.2 (18-07-2025)
- Update to latest version from filebrowser/filebrowser (changelog : https://github.com/filebrowser/filebrowser/releases)
## 2.37.0 (12-07-2025)

- Update to latest version from filebrowser/filebrowser (changelog : https://github.com/filebrowser/filebrowser/releases)

## 2.36.1 (05-07-2025)

- Update to latest version from filebrowser/filebrowser (changelog : https://github.com/filebrowser/filebrowser/releases)

## 2.33.10 (28-06-2025)

- Update to latest version from filebrowser/filebrowser (changelog : https://github.com/filebrowser/filebrowser/releases)

## 2.33.0 (21-06-2025)

- Update to latest version from filebrowser/filebrowser (changelog : https://github.com/filebrowser/filebrowser/releases)

## 2.32.0 (09-05-2025)

- Requires homeassistant core > 2025.5.0
- Update to latest image

## 2.23.0_14 (21-04-2024)

- Fix : allows absence of legacy folders (addons_config and addons_autoscripts)

## 2.23.0_13 (06-04-2024)

- Allow mdadm RAID (thanks @zagi988)

## 2.23.0_12 (08-01-2024)

- Minor bugs fixed
- Fix : allow secrets https://github.com/alexbelgium/hassio-addons/issues/1163

## 2.23.0_11 (05-01-2024)

- Minor bugs fixed
- Fix : healthcheck for https (thanks @encryptix) https://github.com/alexbelgium/hassio-addons/issues/1155

## 2.23.0_10 (30-12-2023)

- Minor bugs fixed
- Fix : correct cache for thumbnails creation
- Feat : new addon option to disable_thumbnails (set disable_thumbnails to true or false ; default true for speed)

## 2.23.0_8 (20-12-2023)

- Minor bugs fixed
- Update of global scripts

## 2.23.0_7 (25-11-2023)

- Symlink addons_config and addons_autoscripts in /config to allow the same behavior as prior to the new HA logic to handle config mountpoints
- Restore database.db persistence

## 2.23.0_reverted5 (21-11-2023)

- MAJOR CHANGE : new HA config logic implemented. Files are now located in the addon config file, that can be accessed from the addon_configs folder from my filebrowser or cloudcommander addons. Migration of data, custom configs, and custom scripts should be automatic. Please be sure to update all your links however ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/
- Homeassistant config accessible in /homeassistant folder ; all addons config in /addons_config ; this addon config in /config

## 2.23.0_reverted (29-09-2023)

- Minor bugs fixed
- Revert to 2.23.0 to avoid tus interference with ingress

## 2.25.0 (16-09-2023)

- Update to latest version from filebrowser/filebrowser

## 2.24.2 (27-08-2023)

- Update to latest version from filebrowser/filebrowser
- Switch upstream image to filebrowser/filebrowser
- Improve speed for larger folders
- Feat : cifsdomain added
- Implemented healthcheck
- Add NTFS support
- Disable external port by default
- WARNING : update to supervisor 2022.11 before installing

## 2.23.0 (08-11-2022)

- Update to latest version from hurlenko/filebrowser-docker

## 2.22.4 (23-07-2022)

- Update to latest version from hurlenko/filebrowser-docker

## 2.22.3 (07-07-2022)

- Update to latest version from hurlenko/filebrowser-docker

## 2.22.2 (05-07-2022)

- Update to latest version from hurlenko/filebrowser-docker

## 2.22.1 (09-06-2022)

- Update to latest version from hurlenko/filebrowser-docker

## 2.22.0 (06-06-2022)

- Update to latest version from hurlenko/filebrowser-docker
- Add codenotary sign

## 2.21.1 (23-02-2022)

- Update to latest version from hurlenko/filebrowser-docker

## 2.21.0 (22-02-2022)

- Update to latest version from hurlenko/filebrowser-docker
- Cleanup: config base folder changed to /config/addons_config (thanks @bruvv)

## 2.20.1 (23-12-2021)

- Update to latest version from hurlenko/filebrowser-docker
- Mount ssl in write
- New standardized logic for Dockerfile build and packages installation
- Mount nvme drives

## 2.19.0 (25-11-2021)

- Update to latest version from hurlenko/filebrowser-docker
- Allow mounting local drives by label. Just pust the label instead of sda1 for example

## 2.18.0 (02-11-2021)

- Update to latest version from hurlenko/filebrowser-docker
- Allow mounting of devices up to sdg2
- Allow uploads >16mb
- Allow local mount in protected mode
- SMB : accepts several disks separated by commas mounted in /mnt/$sharename

## 2.17.2 (28-08-2021)

- Update to latest version from hurlenko/filebrowser-docker

## 2.17.1 (26-08-2021)

- Update to latest version from hurlenko/filebrowser-docker

## 2.17.0 (24-08-2021)

- Update to latest version from hurlenko/filebrowser-docker

## 2.16.1 (07-08-2021)

- Update to latest version from hurlenko/filebrowser-docker
- Ingress added
- No auth option made more apparent

## 2.16.0 (29-07-2021)

- Update to latest version from hurlenko/filebrowser-docker
- Add banner in log
- Update smb mount code
- Allow mount local drives (needs priviledged mode)

## 2.15.0

- Update to latest version from hurlenko/filebrowser-docker

## 2.14.1

- Update to latest version from hurlenko/filebrowser-docker

## 2.13.0

- Update to latest version from hurlenko/filebrowser-docker

## 2.12.1

- Update to latest version from hurlenko/filebrowser-docker

## 2.12.0

- Update to latest version from hurlenko/filebrowser-docker
- Allow mounting shares named \ip\share in addition to //ip/share

## 2.11.0

- Update to latest version from hurlenko/filebrowser-docker
- Added ssl
- New feature : mount smb share in protected mode
- New feature : mount multiple smb shares
- New config/feature : mount smbv1
- Changed path : changed smb mount path from /storage/externalcifs to /mnt/$NAS name
