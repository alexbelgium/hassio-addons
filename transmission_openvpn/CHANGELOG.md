- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## v5.3.2 (2025-05-31)

- Update to latest version from haugene/docker-transmission-openvpn (changelog : https://github.com/haugene/docker-transmission-openvpn/releases)

## v5.3.1-6 (2023-12-29)

- Minor bugs fixed
- BREAKING CHANGE FOR CUSTOM VPN : if you are using a custom VPN provider, you must remove OPENVPN_CUSTOM_PROVIDER from your addon option and instead set OPENVPN_PROVIDER to "custom", then reference your ovpn file in your "OPENVPN_CONFIG". For example, if AIRVPN has provided to you an \*.ovpn filed named AIRVPN.ovpn, you need to install an addon such as Filebrowser, go in the /config/addons_config/transmission/openvpn folder and put the AIRVPN.ovpn here. Then, in the addon option you need to write "AIRVPN" in the "OPENVPN_CONFIG" option
- Removed (not used anymore) : "OPENVPN_CUSTOM_PROVIDER", "OPENVPN_CUSTOM_PROVIDER_OVPN_LOCATION", "TRANSMISSION_V3_UPDATE"

## v5.3.1 (2023-12-09)

- Update to latest version from haugene/docker-transmission-openvpn

## v5.2.0-6 (2023-11-30)

- Minor bugs fixed
- Feat : activate incomplete dir by default if the addon option is activated https://github.com/alexbelgium/hassio-addons/issues/1107

## v5.2.0-5 (2023-11-29)

- Minor bugs fixed
- Fix : WEBPROXY starting

## v5.2.0-4 (2023-11-28)

- Minor bugs fixed
- Feat : addition of the WEBPROXY. It is enabled by default on port 8118 but can be disabled using the addon option "WEBPROXY_ENABLED". More informations : https://haugene.github.io/docker-transmission-openvpn/web-proxy/ (thanks @tutorempire)

## v5.2.0-2 (2023-11-28)

- Feat : addition of custom environement variable through the 01-config_yaml.sh logic. Further infos : https://github.com/alexbelgium/hassio-addons/wiki/Addons-feature:-add-env-variables

## v5.2.0 (2023-09-09)

- Update to latest version from haugene/docker-transmission-openvpn

## v5.1.0-3 (2023-09-04)

- Minor bugs fixed
- Fix https://github.com/alexbelgium/hassio-addons/issues/978

## v5.1.0 (2023-09-02)

- Update to latest version from haugene/docker-transmission-openvpn
- Fix : allow custom providers with names based on mullvad
- Feat : cifsdomain added

## v5.0.2 (2023-04-21)

- Update to latest version from haugene/docker-transmission-openvpn

## v5.0.0 (2023-04-15)

- Update to latest version from haugene/docker-transmission-openvpn
- Implemented healthcheck
- Mullvad fix @Blogshot
- WARNING : update to supervisor 2022.11 before installing

## v4.3.2 (2022-11-19)

- Update to latest version from haugene/docker-transmission-openvpn
- BREAKING CHANGE : update your "LOCAL_NETWORK" from "192.168.178.0/16" to "192.168.178.0/24"

## 4.2 (2022-11-11)

- Update to latest version from haugene/docker-transmission-openvpn
- Auto addon restart if tunnel down
- If no ui after install, please delete your settings.json file and restart
- Allows changing default download folder without deleting settings.json
- Optional transmission v3 (remove and readd torrents)
- Allow using custom ovpn file

## 4.0 (2022-06-02)

- Update to latest version from haugene/docker-transmission-openvpn
- Initial build
