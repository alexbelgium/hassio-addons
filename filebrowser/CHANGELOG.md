
## 2.19.0 (25-11-2021)
- Update to latest version from hurlenko/filebrowser-docker
- Allow mounting local drives by label. Just pust the label instead of sda1 for example

## 2.18.0 (02-11-2021)

- Update to latest version from hurlenko/filebrowser-docker
- Allow mounting of devices up to sdg2
- Allow uploads >16mb
- Allow local mount in protected mode
- Improve SMB mount code to v1.5 ; accepts several network disks separated by commas (//123.12.12.12/share,//123.12.12.12/hello) that are mount to /mnt/$sharename

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
