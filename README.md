# Home assistant add-on: alexbelgium

<!-- markdownlint-disable MD033 -->

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)
![update-badge](https://img.shields.io/github/last-commit/alexbelgium/hassio-addons?label=last%20update)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)
[![Statistics](https://github.com/alexbelgium/hassio-addons/workflows/Generate%20weekly%20stats/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly_stats.yaml)

[support-badge]: https://camo.githubusercontent.com/f4dbb995049f512fdc97fcc9e022ac243fa38c408510df9d46c7467d0970d959/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f537570706f72742d7468726561642d677265656e2e737667

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

_Thanks to all contributors !_

[![contributors](https://contrib.rocks/image?repo=alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/graphs/contributors)

Stargazers locations :

![map](https://raw.githubusercontent.com/alexbelgium/hassio-addons/refs/heads/master/.github/stargazer_map.png)

## About

Home Assistant allows anyone to create add-on repositories to share their
add-ons for Home Assistant easily. This repository is one of those repositories,
providing extra Home Assistant add-ons for your installation.

The primary goal of this project is to provide you (as a Home Assistant user)
with additional, high quality, add-ons that allow you to take your automated
home to the next level.

## Installation

[![Add repository on my Home Assistant][repository-badge]][repository-url]

If you want to do add the repository manually, please follow the procedure highlighted in the [Home Assistant website](https://home-assistant.io/hassio/installing_third_party_addons). Use the following URL to add this repository: https://github.com/alexbelgium/hassio-addons

## Statistics

### Number of addons

- In the repository : 1
- Installed : 1222

### Top 3

1. Addons_updater (1222x)
2. Lidarr_nas (0x)
3. Overseerr (0x)

### Architectures used

- amd64: 61%
- aarch64: 37%
- armv7: 2%

### Stars evolution

[![Star History Chart](https://api.star-history.com/svg?repos=alexbelgium/hassio-addons&type=Date)](https://star-history.com/#alexbelgium/hassio-addons&Date)

## Add-ons provided by this repository


&#10003;  [Repository Updater](addons_updater/) : Automatic addons update by aligning version tag with upstream releases

&emsp;&emsp;![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faddons_updater%2Fconfig.json)
![aarch64][aarch64-badge]
![amd64][amd64-badge]
![armv7][armv7-badge]

## Support

Got questions?

You have several options to get them answered:

- The Home Assistant [Community Forum][forum].
- This repository issues list

[aarch64-badge]: https://img.shields.io/badge/aarch64--green.svg?logo=arm
[amd64-badge]: https://img.shields.io/badge/amd64--green.svg?logo=amd
[armv7-badge]: https://img.shields.io/badge/armv7--green.svg?logo=arm
[aarch64no-badge]: https://img.shields.io/badge/aarch64--orange.svg?logo=arm
[amd64no-badge]: https://img.shields.io/badge/amd64--orange.svg?logo=amd
[armv7no-badge]: https://img.shields.io/badge/armv7--orange.svg?logo=arm
[ingress-badge]: https://img.shields.io/badge/-ingress-blueviolet.svg?logo=Ingress
[mariadb-badge]: https://img.shields.io/badge/Service-MariaDB-green.svg?logo=mariadb&logoColor=white
[mqtt-badge]: https://img.shields.io/badge/Service-MQTT-green.svg?logo=chromecast&logoColor=white
[localdisks-badge]: https://img.shields.io/badge/Mounts-localdisks-blue.svg
[smb-badge]: https://img.shields.io/badge/Mounts-networkdisks-blue.svg
[full_access-badge]: https://img.shields.io/badge/Requires-full_access-orange.svg
[forum]: https://community.home-assistant.io/t/alexbelgium-repo-60-addons
[repository-badge]: https://img.shields.io/badge/Add%20repository%20to%20my-Home%20Assistant-41BDF5?logo=home-assistant&style=for-the-badge
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons
