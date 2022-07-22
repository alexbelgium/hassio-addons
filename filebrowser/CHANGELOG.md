
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
