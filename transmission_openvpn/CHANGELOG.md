- Feat : addition of custom environement variable through the 01-config_yaml.sh logic. Further infos : https://github.com/alexbelgium/hassio-addons/wiki/Add%E2%80%90ons-feature-:-add-env-variables

### v5.2.0-2 (28-11-2023)
- Minor bugs fixed

## v5.2.0 (09-09-2023)
- Update to latest version from haugene/docker-transmission-openvpn

### v5.1.0-3 (04-09-2023)
- Minor bugs fixed
- Fix https://github.com/alexbelgium/hassio-addons/issues/978

## v5.1.0 (02-09-2023)
- Update to latest version from haugene/docker-transmission-openvpn
- Fix : allow custom providers with names based on mullvad
- Feat : cifsdomain added

## v5.0.2 (21-04-2023)

- Update to latest version from haugene/docker-transmission-openvpn

## v5.0.0 (15-04-2023)

- Update to latest version from haugene/docker-transmission-openvpn
- Implemented healthcheck
- Mullvad fix @Blogshot
- WARNING : update to supervisor 2022.11 before installing

## v4.3.2 (19-11-2022)

- Update to latest version from haugene/docker-transmission-openvpn
- BREAKING CHANGE : update your "LOCAL_NETWORK" from "192.168.178.0/16" to "192.168.178.0/24"

## 4.2 (11-11-2022)

- Update to latest version from haugene/docker-transmission-openvpn
- Auto addon restart if tunnel down
- If no ui after install, please delete your settings.json file and restart
- Allows changing default download folder without deleting settings.json
- Optional transmission v3 (remove and readd torrents)
- Allow using custom ovpn file

## 4.0 (02-06-2022)

- Update to latest version from haugene/docker-transmission-openvpn
- Initial build
