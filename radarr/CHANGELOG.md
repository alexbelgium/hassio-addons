- Cleanup: config base folder changed to /config/addons_config (thanks @bruvv)
- New standardized logic for Dockerfile build and packages installation
- Allow mounting local drives by label. Just pust the label instead of sda1 for example
- Improve SMB mount code to v1.5 ; accepts several network disks separated by commas (//123.12.12.12/share,//123.12.12.12/hello) that are mount to /mnt/$sharename
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
- Enables PUID/GUID options
