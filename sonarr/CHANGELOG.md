
## 4.0.0.725 (18-11-2023)
- Update to latest version from linuxserver/docker-sonarr

## 4.0.0.719 (11-11-2023)
- Update to latest version from linuxserver/docker-sonarr

## 4.0.0.710 (04-11-2023)
- Update to latest version from linuxserver/docker-sonarr
### 4.0.0.703-2 (01-11-2023)
- Minor bugs fixed
- Fix : disable authentification when using ingress

## 4.0.0.703 (28-10-2023)
- Update to latest version from linuxserver/docker-sonarr

## 4.0.0.700 (20-10-2023)
- Update to latest version from linuxserver/docker-sonarr

## 4.0.0.697 (14-10-2023)
- Update to latest version from linuxserver/docker-sonarr
- Breaking change : update to v4
- Arm32v7 discontinued by linuxserver, latest working version pinned

### 3.0.10.1567-2 (19-03-2023)

- Minor bugs fixed
- Corrected ingress bug https://github.com/alexbelgium/hassio-addons/issues/758

## 3.0.10.1567 (18-03-2023)

- Update to latest version from linuxserver/docker-sonarr
- Implemented healthcheck

## 3.0.10.1566 (11-03-2023)

- Update to latest version from linuxserver/docker-sonarr
- Add ingress_disabled option
- Ingress addition
- BaseUrl definition to "sonarr"
- WARNING : update to supervisor 2022.11 before installing

## 3.0.9.1549 (09-08-2022)

- Update to latest version from linuxserver/docker-sonarr

## 3.0.8.1507 (26-04-2022)

- Update to latest version from linuxserver/docker-sonarr
- Add codenotary sign

## 3.0.7.1477 (06-03-2022)

- Update to latest version from linuxserver/docker-sonarr

## 3.0.6.1342-6 (03-01-2022)

- Cleanup: config base folder changed to /config/addons_config (thanks @bruvv)
- New standardized logic for Dockerfile build and packages installation
- Allow mounting local drives by label. Just pust the label instead of sda1 for example
- Allow mounting local drives by label. Just pust the label instead of sda1 for example
- SMB : accepts several disks separated by commas mounted in /mnt/$sharename

## 3.0.6.1342 (02-10-2021)

- Update to latest version from linuxserver/docker-sonarr

## 3.0.6.1335 (30-09-2021)

- Update to latest version from linuxserver/docker-sonarr
- Improved cifs mount code to make it universal
- Breaking changes : multiple network disks must be separated by a "," and they are mounted to a folder with the name of the external share.

## 3.0.6.1265 (18-06-2021)

- Update to latest version from linuxserver/docker-sonarr

## 3.0.2.4552

- Update to latest version from linuxserver/docker-sonarr
- Enables PUID/PGID options
