- New standardized logic for Dockerfile build and packages installation
- Allow mounting local drives by label. Just pust the label instead of sda1 for example
- Allow mounting local drives by label. Just pust the label instead of sda1 for example
- Improve SMB mount code to v1.5 ; accepts several network disks separated by commas (//123.12.12.12/share,//123.12.12.12/hello) that are mount to /mnt/$sharename

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
- Enables PUID/GUID options
