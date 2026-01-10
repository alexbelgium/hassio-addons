## breaking_versions: 10.11.5-2 (2026-01-09)
- Minor bugs fixed
## breaking_versions: 10.11.5 (2025-12-20)
- Minor bugs fixed

## 10.11.5 (2025-12-20)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)
## breaking_versions: 10.11.4-1 (2025-12-13)
- Minor bugs fixed
## 10.11.4-1 (2025-12-07)
- Avoid deleting the configured data directory when it matches the legacy path while rebuilding symlinks.

## breaking_versions: 10.11.4 (2025-12-06)
- Minor bugs fixed

## 10.11.4 (2025-12-06)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)
## breaking_versions: 10.11.3-2 (2025-11-28)
- Minor bugs fixed
## 10.11.3-2 (2025-11-30)
- Allow `i915_enable_guc` to be applied on hosts that expose the runtime parameter by granting raw I/O capability and AppArmor access to `/sys/module/i915/parameters/enable_guc`.

## breaking_versions: 10.11.3-1 (2025-11-23)
- Minor bugs fixed

## 10.11.3-1 (2025-11-23)
- Fix optional `i915_enable_guc` setting so the add-on no longer requires a value after updates.

## 10.11.3 (2025-11-22)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)
- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

## breaking_versions: 10.11.3 (2025-11-17)
- Minor bugs fixed

## 10.11.3 (2025-11-17)
- Add optional `i915_enable_guc` setting to apply Intel GuC mode at startup for improved hardware encoding stability, with runtime-only changes that rely on the host exposing `/sys/module/i915/parameters/enable_guc`.

## 10.11.2 (2025-11-08)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 10.11.1 (2025-11-01)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)
- Disabled migration script

## 10.10.7 (2025-04-12)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.10.6 (2025-02-21)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)
- BREAKING CHANGE : Change default data location to /share rather than main system config folder. This is fully customizable through the data_location option. Also, is now allowing to use /config for a seemless backup of the library with the addon (not recommended as will mean very large backups at each update)
- Manual update forced

## 10.10.5 (2025-02-01)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.10.4 (2025-01-25)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.10.3 (2024-11-23)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.10.1 (2024-11-09)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.10.0 (2024-11-02)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.9.11 (2024-09-14)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.9.10 (2024-08-31)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.9.9 (2024-08-10)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.9.8 (2024-07-27)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.9.7 (2024-06-29)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.9.6 (2024-06-08)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)
## 10.9.3-2 (2024-06-01)
- Minor bugs fixed

## 10.9.3 (2024-06-01)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.9.2 (2024-05-18)
- Update to latest version from linuxserver/docker-jellyfin (changelog : https://github.com/linuxserver/docker-jellyfin/releases)

## 10.8.13-3-3 (2023-12-10)

- Minor bugs fixed
- Corrected 00-smb_mounts.sh logic for servers that don't support anonymous access

## 10.8.13-1 (2023-12-04)

- Allows non-admin users to use paperless from HA sidebar

## 10.8.13 (2023-12-02)

- Update to latest version from linuxserver/docker-jellyfin
## 10.8.12-4 (2023-11-21)

- Minor bugs fixed
## 10.8.12-2 (2023-11-12)

- Minor bugs fixed

## 10.8.12 (2023-11-11)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.11 (2023-09-30)

- Update to latest version from linuxserver/docker-jellyfin
- Arm32v7 discontinued by linuxserver, latest working version pinned

## 10.8.10-6 (2023-05-08)

- Minor bugs fixed

## 10.8.10-5 (2023-05-04)

- Minor bugs fixed

## 10.8.10-2 (2023-05-04)

- Minor bugs fixed
- Add symlink for transcodes folder https://github.com/alexbelgium/hassio-addons/issues/777

## 10.8.10 (2023-04-29)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.9 (2023-03-25)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.9-1-ls203 (2023-03-11)

- Update to latest version from linuxserver/docker-jellyfin
- Implemented healthcheck

## 10.8.9-1-ls202 (2023-03-04)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.9-1-ls201 (2023-02-25)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.9-1-ls200 (2023-02-19)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.9-1-ls199 (2023-02-11)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.9-1-ls198 (2023-02-04)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.9-1-ls197 (2023-01-28)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.8-1-ls196 (2023-01-21)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.8-1-ls195 (2023-01-14)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.8-1-ls194 (2023-01-07)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.8-1-ls193 (2022-12-25)

- Update to latest version from linuxserver/docker-jellyfin
- Fixed ingress
- Expose web folder to /config/addons_config/jellyfin/web

## 10.8.8-1-ls192 (2022-12-13)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.8-1-ls191 (2022-12-10)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.8-1-ls190 (2022-12-01)

- Update to latest version from linuxserver/docker-jellyfin
- WARNING : update to supervisor 2022.11 before installing

## 10.8.7-1-ls189 (2022-11-26)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.7-1-ls188 (2022-11-19)

- Update to latest version from linuxserver/docker-jellyfin
- Addition of hardware drivers for AMD, intel, RFFMPEG

## 10.8.7-1-ls186 (2022-11-02)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.6-1-ls185 (2022-11-01)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.5-1-ls184 (2022-10-29)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.5-1-ls183 (2022-10-22)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.5-1-ls182 (2022-10-15)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.5-1-ls181 (2022-09-30)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.5-1-ls180 (2022-09-27)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.4-1-ls179 (2022-09-24)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.4-1-ls178 (2022-09-09)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.4-1-ls177 (2022-08-20)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.4-1-ls176 (2022-08-16)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.3-1-ls175 (2022-08-11)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.3-1-ls174 (2022-08-06)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.3-1-ls173 (2022-08-04)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.1-1-ls171 (2022-07-23)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.1-1-ls170 (2022-07-16)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.1-1-ls169 (2022-07-09)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.1-1-ls168 (2022-07-02)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.1-1-ls167 (2022-06-28)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.0-1-ls166 (2022-06-25)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.0-1-ls165 (2022-06-18)

- Update to latest version from linuxserver/docker-jellyfin

## 10.8.0-1-ls164 (2022-06-14)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls162 (2022-06-11)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls161 (2022-05-31)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls160 (2022-05-21)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls159 (2022-05-12)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls158 (2022-05-05)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls157 (2022-04-02)

- Update to latest version from linuxserver/docker-jellyfin
- Ingress port changed to avoid conflicts

## 10.7.7-1-ls156 (2022-03-24)

- Update to latest version from linuxserver/docker-jellyfin
- Add codenotary sign
- Addition of ingress

## 10.7.7-1-ls155 (2022-03-17)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls154 (2022-03-11)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls153 (2022-03-05)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls152 (2022-02-24)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls151 (2022-02-17)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls150 (2022-01-20)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.7-1-ls149 (2022-01-15)

- Update to latest version from linuxserver/docker-jellyfin
- "host_network": true to enable UPNP, chromecast, ...
- Code to repair database due to a bug that occured when the config location changed

## 10.7.7-1-ls148 (2022-01-06)

- Update to latest version from linuxserver/docker-jellyfin
- Cleanup: config base folder changed to /config/addons_config (thanks @bruvv)
- New standardized logic for Dockerfile build and packages installation
- Add local mount (see readme)
- Added watchdog feature
- Allow mounting of devices up to sdg2
- SMB : accepts several disks separated by commas mounted in /mnt/$sharename

## 10.7.7-1-ls130 (2021-09-06)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.6-1-ls118 (2021-06-19)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.5-1-ls113 (2021-05-20)

- Update to latest version from linuxserver/docker-jellyfin
- Add banner to log

## 10.7.5-1-ls112 (2021-05-14)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.5-1-ls111 (2021-05-06)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.2-1-ls110 (2021-04-30)

- Update to latest version from linuxserver/docker-jellyfin

## 10.7.2-1-ls109

- Update to latest version from linuxserver/docker-jellyfin
- Enables PUID/PGID options
- New feature : mount smb share in protected mode
- New feature : mount multiple smb shares
- New config/feature : mount smbv1
- Changed path : changed smb mount path from /storage/externalcifs to /mnt/$NAS name
- Removed feature : ability to remove protection and mount local hdd, to increase the addon score
