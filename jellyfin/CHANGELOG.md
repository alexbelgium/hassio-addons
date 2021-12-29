- Cleanup: config base folder changed to /config/addons_config
- New standardized logic for Dockerfile build and packages installation
- Add local mount (see readme)
- Added watchdog feature
- Allow mounting of devices up to sdg2
- Improve SMB mount code to v1.5 ; accepts several network disks separated by commas (//123.12.12.12/share,//123.12.12.12/hello) that are mount to /mnt/$sharename

## 10.7.7-1-ls130 (06-09-2021)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.6-1-ls118 (19-06-2021)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.5-1-ls113 (20-05-2021)

- Update to latest version from linuxserver/docker-jellyfin
- Add banner to log

## 10.7.5-1-ls112 (14-05-2021)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.5-1-ls111 (06-05-2021)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.2-1-ls110 (30-04-2021)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.2-1-ls109

- Update to latest version from linuxserver/docker-jellyfin
- Enables PUID/GUID options
- New feature : mount smb share in protected mode
- New feature : mount multiple smb shares
- New config/feature : mount smbv1
- Changed path : changed smb mount path from /storage/externalcifs to /mnt/$NAS name
- Removed feature : ability to remove protection and mount local hdd, to increase the addon score
