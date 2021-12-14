
## 20211210 (12-12-2021)
- Update to latest version from photoprism/photoprism
- New standardized logic for Dockerfile build and packages installation
- Allow mounting local drives by label. Just pust the label instead of sda1 for example
- Allow mounting of devices up to sdg2
- Improve SMB mount code to v1.5 ; accepts several network disks separated by commas (//123.12.12.12/share,//123.12.12.12/hello) that are mount to /mnt/$sharename

## 210217-49039368 (29-09-2021)

- Update to latest version from photoprism/photoprism
- Allow mounting smb and local disks
- Allow custom paths from options
- Allow any custom photoprism flags
- Initial release
