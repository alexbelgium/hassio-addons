### 27.1.3 (03-11-2023)
- Minor bugs fixed
### 27.1.2-3 (16-10-2023)
- Minor bugs fixed
- Feat : optional configuration of php (env_memory_limit ; env_post_max_size ; env_upload_max_filesize)

### 27.1.2-2 (07-10-2023)
- Minor bugs fixed
- Fix : cannot write in data folder

## 27.1.2 (07-10-2023)
- Update to latest version from linuxserver/docker-nextcloud
- Increase start timer

### 27.1.1-3 (24-09-2023)
- Automatic disable maintenance

### 27.1.1-2 (24-09-2023)
- Minor bugs fixed

## 27.1.1 (23-09-2023)
- Update to latest version from linuxserver/docker-nextcloud
### 27.0.2-10 (06-09-2023)
- Minor bugs fixed
### 27.0.2-9 (06-09-2023)
- Minor bugs fixed

### 27.0.2-4 (05-09-2023)
- Minor bugs fixed
- Fit : new variable "default_phone_region" https://github.com/alexbelgium/hassio-addons/issues/981

### 27.0.2-3 (24-08-2023)
- Fix : healthcheck timeouts @https://github.com/alexbelgium/hassio-addons/issues/956
- Fix : nginx timeouts

### 27.0.2-2 (22-08-2023)
- Minor bugs fixed
- Fix typo in nextcloud nginx_addition #950 @chocomega

## 27.0.2 (19-08-2023)
- Update to latest version from linuxserver/docker-nextcloud
## 27.0.2 (12-08-2023)

- Update to latest version from linuxserver/docker-nextcloud

### 27.0.1-7 (22-07-2023)
- Minor bugs fixed
- &#9888; MAJOR BREAKING CHANGE:
  - Code rewrite due in upstream logic change https://info.linuxserver.io/issues/2023-06-25-nextcloud
  - Please backup before updating
  - If you have not upgraded to v27 with web interface before updating IT WILL STOP WORKING !
- Increase timeouts for larger uploads
- Feat : disable_updates will now only disable app updates, not nextcloud's
- Feat : disable_updates_nextcloud will disable nextcloud updates which can lead to significant issues
- Force nextcloud app automatic update with addon

## 27.0.0 (17-06-2023)

- Update to latest version from linuxserver/docker-nextcloud
- Automatically attempts to disable maintenance mode on start

## 26.0.2 (27-05-2023)

- Update to latest version from linuxserver/docker-nextcloud

### 26.0.1-5 (26-05-2023)

- Minor bugs fixed
- Feat : cifsdomain added
- Feat : Align max upload size to 8192M https://github.com/alexbelgium/hassio-addons/issues/846

### 26.0.1-3 (02-05-2023)

- Minor bugs fixed
- Add renderD128 to devices https://github.com/alexbelgium/hassio-addons/pull/820

### 26.0.1-2 (30-04-2023)

- Minor bugs fixed
- Chmod only data folder subdirectories https://github.com/alexbelgium/hassio-addons/issues/818

## 26.0.1 (29-04-2023)

- Update to latest version from linuxserver/docker-nextcloud

### 26.0.0-17 (11-04-2023)

- Minor bugs fixed
- Automatic app updates

### 26.0.0-16 (11-04-2023)

- Minor bugs fixed

### 26.0.0-15 (11-04-2023)

- Minor bugs fixed

### 26.0.0-14 (11-04-2023)

- Minor bugs fixed
- Implement check_data_directory_permissions for data folders in mounted drives

### 26.0.0-12 (02-04-2023)

- Minor bugs fixed
- &#9888; WARNING : please read warning on previous versions before updating
- Prevent downgrades, and instead reinstall the correct version
- Improve PUID/PGID code setting, and avoid minor issues

### 26.0.0-9_updater (01-04-2023)

- Minor bugs fixed
- &#9888; WARNING : PLEASE BACKUP NEXTCLOUD & MARIADB ADDONS BEFORE UPDATING !
- &#9888; WARNING : Enables by default updater at addon start; you can disable it with the option "disable_updates"
- Improved updater code
- Autocorrection of permission errors in data directory

### 26.0.0-4 (26-03-2023)

- Minor bugs fixed
- Fix : solve AGAIN spam of healthcheck in logs

### 26.0.0-3 (26-03-2023)

- Minor bugs fixed
- Fix : bug in launcher script status detector if data is in a mounted directory

### 26.0.0-2 (26-03-2023)

- Minor bugs fixed
- Fix : connection with desktop client https://github.com/alexbelgium/hassio-addons/issues/771
- Improve : status check code https://github.com/alexbelgium/hassio-addons/issues/768
- Fix : reinstallation code https://github.com/alexbelgium/hassio-addons/issues/764

## 26.0.0 (24-03-2023)

- Update to latest version from linuxserver/docker-nextcloud
- auto_update boolean option : automatically updates the nextcloud instance with the container version

### 25.0.5-14 (23-03-2023)

- Minor bugs fixed
- Revert version number to align with container

### 25.0.4-11 (22-03-2023)

- Minor bugs fixed
- Implemented safety check that reinstalls nextcloud if issue detected https://github.com/alexbelgium/hassio-addons/issues/764
- Implemented healthcheck
- Redirect crond errors to addon logs https://github.com/alexbelgium/hassio-addons/issues/752
- Improve elasticsearch integration
- Links nginx & php logs with addon logs
- Optimized nginx code to remove server error messages
- Allows calling directly occ instead of needing full path
- Corrected elastisearch server definition and test

## 25.0.4 (25-02-2023)

- Update to latest version from linuxserver/docker-nextcloud

## 25.0.3 (12-02-2023)

- WARNING! : this is a major code update. Make sure to have a full update of /config, /share and your nextcloud addon before updating. I take no responsibility for lost data!
- Update to latest version from linuxserver/docker-nextcloud
- WARNING : update to supervisor 2022.11 before installing

## 25.0.0 (20-10-2022)

- Update to latest version from linuxserver/docker-nextcloud

## 24.0.6 (08-10-2022)

- Update to latest version from linuxserver/docker-nextcloud

## 24.0.5 (09-09-2022)

- Update to latest version from linuxserver/docker-nextcloud

## 24.0.4 (13-08-2022)

- Update to latest version from linuxserver/docker-nextcloud
- Allow installation of custom apk files with parameter "additional_apps"

## 24.0.3 (19-07-2022)

- Update to latest version from linuxserver/docker-nextcloud

## 24.0.2 (21-06-2022)

- Update to latest version from linuxserver/docker-nextcloud

## 24.0.1 (24-05-2022)

- Update to latest version from linuxserver/docker-nextcloud

## 23.0.4 (22-04-2022)

- Update to latest version from linuxserver/docker-nextcloud
- Fix : correct bug preventing start
- Add codenotary sign

## 23.0.3 (22-03-2022)

- Update to latest version from linuxserver/docker-nextcloud

## 23.0.2 (16-02-2022)

- Update to latest version from linuxserver/docker-nextcloud
- Automatic mount of local and smb mounts (see readme)
- New "Data directory" option that allows to define the folder where data are stored
- Provides MariaDB addon information to use it as database on first installation
- MultiOCR: in OCRLANG field use comma separated value. Ex: fra,deu
- Max file size increased to 10Go
- New standardized logic for Dockerfile build and packages installation

## 23.0.0 (30-11-2021)

- Update to latest version from linuxserver/docker-nextcloud

## 22.2.3 (16-11-2021)

- Update to latest version from linuxserver/docker-nextcloud

## 22.2.2 (13-11-2021)

- Update to latest version from linuxserver/docker-nextcloud
- Repaired use own certs
- Repaired increment of trusted domains
- Repaired setting OCR language
- New optional config : enable elasticsearch (requires to run in parallel elasticsearch addon)
- Repaired default data setting in /share/nextcloud

## 22.2.0 (02-10-2021)

- Update to latest version from linuxserver/docker-nextcloud
- Faster reboot by only chowning files if user change
- BREAKING CHANGE : comma separated domains instead of list
- Allow usage of own certificates
- OCR fixed
- glibc compatibility added

## 22.1.1 (31-08-2021)

- Update to latest version from linuxserver/docker-nextcloud

## 22.1.0 (07-08-2021)

- Update to latest version from linuxserver/docker-nextcloud

## 22.0.0 (07-07-2021)

- Update to latest version from linuxserver/docker-nextcloud

## 21.0.3 (02-07-2021)

- Update to latest version from linuxserver/docker-nextcloud

## 21.0.2 (20-05-2021)

- Update to latest version from linuxserver/docker-nextcloud

## 21.0.1

- Update to latest version from linuxserver/docker-nextcloud

## 21.0.0

- Update to latest version from linuxserver/docker-nextcloud
- Enables PUID/PGID options
