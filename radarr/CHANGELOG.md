
## 5.26.2.10099 (21-06-2025)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.25.0.10024 (31-05-2025)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.23.3.9987 (24-05-2025)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.22.4.9896 (26-04-2025)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.21.1.9799 (29-03-2025)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.20.2.9777 (22-03-2025)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.19.3.9730 (01-03-2025)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.18.4.9674 (08-02-2025)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.17.2.9580 (11-01-2025)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.16.3.9541 (21-12-2024)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.15.1.9463 (23-11-2024)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.14.0.9383 (02-11-2024)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.12.2.9335 (19-10-2024)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.11.0.9244 (28-09-2024)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.9.1.9070 (24-08-2024)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.8.3.8933 (27-07-2024)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.7.0.8882 (22-06-2024)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.6.0.8846 (18-05-2024)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)
## 5.4.6.8723-5 (22-04-2024)
- Fix : not starting

## 5.4.6.8723-4 (21-04-2024)
- BREAKING CHANGE : ingress_disabled option removed. Instead, a new option connection_mode is added. It has 3 modes : ingress_noauth (default, disables authentification to allow a seamless ingress integration), noingress_auth (disables ingress to allow a simpler external url, enables authentification), ingress_auth (enables both ingress and authentification). Thanks @Ni3kjm !

## 5.4.6.8723 (20-04-2024)
- Update to latest version from linuxserver/docker-radarr (changelog : https://github.com/linuxserver/docker-radarr/releases)

## 5.3.6.8612 (24-02-2024)

- Update to latest version from linuxserver/docker-radarr
- There is now an official addon in the community repository, you should migrate to it ! However it does not support ingress ;)

## 5.2.6.8376 (30-12-2023)

- Update to latest version from linuxserver/docker-radarr
## 5.1.3.8246-4 (02-12-2023)

- Minor bugs fixed
- Send crond messages to addon logs

## 5.1.3.8246 (18-11-2023)

- Update to latest version from linuxserver/docker-radarr
## 5.0.3.8127-2 (01-11-2023)

- Minor bugs fixed
- Fix : disable authentification when using ingress

## 5.0.3.8127 (14-10-2023)

- Update to latest version from linuxserver/docker-radarr

## 4.7.5.7809-2 (27-09-2023)

- Minor bugs fixed

## 4.7.5.7809 (19-08-2023)

- Update to latest version from linuxserver/docker-radarr
- armv7 discontinued by lsio

## 4.6.4.7568 (08-07-2023)

- Update to latest version from linuxserver/docker-radarr

## 4.5.2.7388 (03-06-2023)

- Update to latest version from linuxserver/docker-radarr
## 4.4.4.7068-2 (12-05-2023)

- Minor bugs fixed

## 4.4.4.7068 (21-04-2023)

- Update to latest version from linuxserver/docker-radarr
## 4.3.2.6857-21 (17-03-2023)

- Minor bugs fixed
- Solve signalr error https://github.com/alexbelgium/hassio-addons/issues/757
- Implemented healthcheck
- Add ingress_disabled option
- Ingress addition
- BaseUrl definition to "radarr"

## 4.3.2.6857 (07-01-2023)

- Update to latest version from linuxserver/docker-radarr
- WARNING : update to supervisor 2022.11 before installing

## 4.2.4.6635 (27-09-2022)

- Update to latest version from linuxserver/docker-radarr

## 4.1.0.6175 (16-04-2022)

- Update to latest version from linuxserver/docker-radarr
- Add codenotary sign

## 4.0.5.5981 (06-03-2022)

- Update to latest version from linuxserver/docker-radarr

## 4.0.4.5922 (31-01-2022)

- Update to latest version from linuxserver/docker-radarr

## 3.2.2.5080-7 (03-01-2022)

- Cleanup: config base folder changed to /config/addons_config (thanks @bruvv)
- New standardized logic for Dockerfile build and packages installation
- Allow mounting local drives by label. Just pust the label instead of sda1 for example
- SMB : accepts several disks separated by commas mounted in /mnt/$sharename
- Breaking changes : multiple network disks must be separated by a "," and they are mounted to a folder with the name of the external share.

## 3.2.2.5080 (04-06-2021)

- Update to latest version from linuxserver/docker-radarr

## 3.2.1.5070 (28-05-2021)

- Update to latest version from linuxserver/docker-radarr

## 3.2.0.5048 (19-05-2021)

- Update to latest version from linuxserver/docker-radarr

## 3.1.1.4954 (05-05-2021)

- Update to latest version from linuxserver/docker-radarr

## 3.0.2.4552

- Update to latest version from linuxserver/docker-radarr
- Enables PUID/PGID options
