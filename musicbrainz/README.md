# Hassio Add-ons by alexbelgium: musicbrainz

## About

[musicbrainz](https://musicbrainz.org/) is an open music encyclopedia that collects music metadata and makes it available to the public.

This addon is based on the [docker image](https://github.com/linuxserver/docker-musicbrainz) from linuxserver.io.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on. The initial import and setup of the database can take quite a long time, dependant on your download speed etc, be patient and don't restart the container before it's complete.
1. Check the logs of the add-on to see if everything went well.
1. You must register here to receive a MusicBrainz code to allow you to receive database updates, it is free. Get Code [here] (https://metabrainz.org/supporters/account-type).


## Configuration

Webui can be found at `<your-ip>:5000`.

[repository]: https://github.com/alexbelgium/hassio-addons
