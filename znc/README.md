# Hassio Add-ons by petersendev: ZNC

## About

[ZNC](http://wiki.znc.in/ZNC) is an IRC network bouncer or BNC. It can detach the client from the actual IRC server, and also from selected channels. Multiple clients from different locations can connect to a single ZNC account simultaneously and therefore appear under the same nickname on IRC.

This addon is based on the [docker image](https://github.com/linuxserver/docker-znc) from linuxserver.io.

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

Webui can be found at `<your-ip>:6500` for http and `<your-ip>:6501` for ssl (self-genererated certificate).

The default login details (change ASAP) are

`login`: admin, `password`: admin


[repository]: https://github.com/petersendev/hassio-addons