- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## v0.14.5-2 (2025-07-23)
- Minor bugs fixed

## v0.14.5 (2025-07-12)
- Update to latest version from Unpackerr/unpackerr (changelog : https://github.com/Unpackerr/unpackerr/releases)

## 0.14.5 (2024-08-03)
- Update to latest version from Unpackerr/unpackerr (changelog : https://github.com/Unpackerr/unpackerr/releases)

## 0.14.0 (2024-07-13)
- Update to latest version from Unpackerr/unpackerr (changelog : https://github.com/Unpackerr/unpackerr/releases)
## 0.13.1-8 (2024-03-13)
- Minor bugs fixed
## 0.13.1-7 (2024-03-13)
- Fix : not starting https://github.com/alexbelgium/hassio-addons/issues/1270

## 0.13.1 (2024-01-27)

- Update to latest version from Unpackerr/unpackerr

## 0.13.0 (2024-01-20)

- Update to latest version from Unpackerr/unpackerr
## 0.12.0-3 (2023-12-31)

- Minor bugs fixed
- Deprecated options watch_path and extraction_path to avoid breakage of the configuration file. Any modifications needs to be done manually using (for example) the Filebrowser addon in /addon_configs/db21ed7f_unpackerr/unpackerr.conf. This also means you'll have to make sure the PUID/PGID specified really correspond to your actual permissions (the app doesn't allow to run as root)

## 0.12.0 (2023-12-30)

- Update to latest version from Unpackerr/unpackerr

- &#9888; MAJOR CHANGE : switch to the new config logic from homeassistant. Your configuration files will have migrated from /config to a folder only accessible from my Filebrowser addon called /addon_configs/db21ed7f_unpackerr. This avoids the addon to mess with your homeassistant configuration folder, and allows to backup the options. Migration of data, custom configs, and custom scripts should be automatic. Please be sure to update all your links however ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/

## testing-e916f00-9-linux-arm64-2023-09-17 (2023-09-17)

- Update to latest version from hotio/unpackerr

## testing-e0c8cc6-7-linux-arm64-2023-09-09 (2023-09-09)

- Update to latest version from hotio/unpackerr

## testing-cache-linux-arm64-2023-08-27 (2023-08-27)

- Update to latest version from hotio/unpackerr

## testing-cd1e492-552-linux-amd64-2023-07-20 (2023-07-20)

- Update to latest version from hotio/unpackerr

## testing-db4370b-2023-03-29 (2023-03-29)

- Update to latest version from hotio/unpackerr

## testing-db4370b-528-linux-arm64-2023-03-29 (2023-03-29)

- Update to latest version from hotio/unpackerr

## testing-5465f08-525-linux-arm64-2023-03-29 (2023-03-29)

- Update to latest version from hotio/unpackerr

## testing-958c97f-514-linux-arm64-2023-02-10 (2023-02-10)

- Update to latest version from hotio/unpackerr

## release-a17d885-2023-01-16 (2023-01-16)

- Update to latest version from hotio/unpackerr

## 0.11.1 (2023-01-21)

- Update to latest version from davidnewhall/unpackerr
- Add local & smb disks mounting
- WARNING : update to supervisor 2022.11 before installing
- Breaking change : define downloads and extraction folder from options
- Feat : allow changing puid pgid

## 0.10.1-2 (2022-10-08)

- Update to latest version from hotio/unpackerr
- Changed upstream image to hotio/unpackerr
- Breaking change : remove default folders config (see Readme)

## 0.10.1 (2022-07-07)

- Update to latest version from davidnewhall/unpackerr

## 0.10.0 (2022-05-10)

- Update to latest version from davidnewhall/unpackerr

## 0.9.9 (2022-05-06)

- Update to latest version from davidnewhall/unpackerr

## v0.9.9 (2022-05-06)

- Update to latest version from davidnewhall/unpackerr
- Initial build
