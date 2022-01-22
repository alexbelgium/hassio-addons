# Wouter's Home Assistant Add-ons: Spotweb by @woutercoppens

## About

This addon was built by [@woutercoppens](https://github.com/woutercoppens/hassio-addons/tree/main/spotweb) and is hosted on this repository.

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

[repository]: https://github.com/alexbelgium/hassio-addons
[spotnet]: https://github.com/spotnet/spotnet/wiki
[spotweb]: https://github.com/spotweb/spotweb
