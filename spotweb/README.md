## &#9888; Open Issue : [🐛 [Spotweb] access denied after rights removal of anonymus, no login prompt (opened 2025-01-18)](https://github.com/alexbelgium/hassio-addons/issues/1725) by [@MijnSpam](https://github.com/MijnSpam)
# Home Assistant Add-ons: Spotweb

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fspotweb%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fspotweb%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fspotweb%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/spotweb/stats.png)

## About

[Spotweb][spotweb] is a decentralized usenet community based on the [Spotnet][spotnet] protocol.

Spotweb is one of the most-featured Spotnet clients currently available, featuring among other things:

- Fast.
- Customizable filter system from within the system.
- Showing and filtering on new spots since the last view.
- Watchlist.
- Integration with Sick Gear , Sick beard and CouchPotato as a 'newznab' provider.
- Sabnzbd and nzbget integration.
- Multi-language.
- Multiple-user ready.

This addon was built by @woutercoppens and is hosted on this repository.

## Installation

Note: This addon requires a mysql database. Make sure you have the MariaDB addon running of use a remote MySQL server.
A database and user will be auto created if the MariaDB addon is detected.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Make sure that the MariaDB addon is installed or use a remote MySQL server.
1. Install the Spotweb add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

Thanks to Ingress support, security and authentication is handled by Home Assistant. Therefore authentication in Spotweb is disabled by default. Spotweb is ready to use after installation through Ingress WebUI.

Spots are retrieved every hour by a background task.
Restart the addon after entering your credentials to force the first sync of spots.

To import your ownsettings.php, place the file in "/config/addons_config/spotweb/ownsettings.php".

[repository]: https://github.com/alexbelgium/hassio-addons
[spotnet]: https://github.com/spotnet/spotnet/wiki
[spotweb]: https://github.com/spotweb/spotweb
