 
## 3.0.0 (2026-10-31)
- Update to latest version from portainer/portainer-ee
## 2.45.3 (2026-10-28)

- Update to Portainer EE 2.45.3, and return to the real Portainer version number for the app version
- Version 2026.10.27 wrongly shipped the `alpine` tag instead of a release; the updater now only follows numeric Portainer releases
- If you have version 2026.10.27 or 2026.10.28 installed, Home Assistant sees 2.45.3 as older and will not offer this update. Uninstalling deletes the Portainer database, so first export it from Portainer itself (Settings > Back up Portainer > Download backup file), then uninstall and reinstall the app, and choose "Restore Portainer from backup" on its first-start screen. Restoring a Home Assistant backup instead would bring back version 2026.10.28
## 2026.10.27 (2026-10-27)
- Update to latest version from portainer/portainer-ee
- Upstream tag : alpine
- Migrate legacy add-on configuration map names to current app configuration terminology.
## 2026.08.01 (2026-08-01)

- Version renamed from `sts`, which Home Assistant could not order and therefore could not reliably offer as an update: the previous version held no number that could order it, so the date of this change is used. The addon itself and the upstream version it tracks are unchanged

 
## sts (2026-08-01)
- Update to latest version from portainer/portainer-ee
## 2.43.0 (2026-07-27)
- Initial release: Portainer Business Edition add-on, based on the Portainer (CE) add-on (#873)
- Ships the `portainer/portainer-ee` binary and web assets; enter a free Business Edition license key in the web UI to unlock BE features (changelog: https://github.com/portainer/portainer/releases)
