# Home assistant add-on: Nextcloud OCR
![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

## About

Forked to add latest version, addition of OCR
- Inital version : https://github.com/petersendev/hassio-addons

[emby](https://emby.media/) organizes video, music, live TV, and photos from personal media libraries and streams them to smart TVs, streaming boxes and mobile devices. This container is packaged as a standalone emby Media Server.

This addon is based on the [docker image](https://github.com/linuxserver/nextcloud) from linuxserver.io.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.


## Configuration

Webui can be found at `<your-ip>:port`.

# How to add trusted domain
Nextcloud requires a whitelist of trusted domains in order to access Nextcloud externally, or even internally from an address that is different from the domain it is initially assessed from. Normally this requires editing of a config file. If you have access to the add-on data storage (i.e. Supervised Installation) then the recommended method is to follow official documentation to add your domain. 

If you are running HASSOS and have no access to edit this file you can add your domain from the web interface through a console app that allows access to the 'occ' command line.

To do this, log into the Nextcloud web interface as an admin user, click the top right user image icon to expand the menu. Select the Apps to go to the app installation page. On the app installation page install an app called 'OCC Web'.

Once installed return to the main page and launch OCCWeb.

When the console is displayed type:

> config:system:get trusted_domains

Warning: overwriting the domain you are currently using will make Nextcloud inaccessible and the add-on will have to be deleted and reinstalled. This will list the current trusted domains. The domains are numbered from 0 so if you have two domains that display the first is domain 0, the second is domain 1. To add another domain:

> config:system:set trusted_domains 2 --value=my.domain.com

Where the number 2 is the now new third domain position in the config file, and 'my.domain.com' is your domain. Type the first command again to see whether the new domain has indeed been added. If it has, you are done!

Based on the linuxserver image

[repository]: https://github.com/alexbelgium/hassio-addons
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg