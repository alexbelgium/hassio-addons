# Aurral

[Aurral](https://github.com/lklynet/aurral) finds new music, gets it, and plays it, all on your own server. It has library-aware recommendations, requests, flows, and playlist imports.
This addon is based on the docker image <https://github.com/lklynet/aurral>

## Configuration

| Option | Default | Description |
|---|---|---|
| `download_folder` | `/share/aurral/downloads` | Path where Aurral writes its downloads, including flows (in a subfolder). Can be under `/share` or `/media`. |

Aurral's data is in `/addon_configs/xxxxxxxx_aurral/data`, or directly in `/addon_configs/xxxxxxxx_aurral` for installs that first started on 3.0.1. Set the Library folder, read-only folders and other paths under `/media` or `/share`.

## Upgrading to 3.0

Read the [Aurral 3.0 release notes](https://github.com/lklynet/aurral/releases/tag/v3.0.0) first. In short:

- Your data stays where it is.
- On first start, Aurral saves copies of the database as `aurral.pre-job-queue.db` and, if Lidarr ran your library, `aurral.pre-lidarr-conversion.db`. They are only needed to roll back to 2.x. Delete them once 3.0 works for you, so that your backups stay small.
- Lidarr mode and Last.fm are gone. Aurral takes over a Lidarr library on first start. To download through Lidarr again, set up the Lidarr plugin in **Settings > Plugins**. It only downloads whole albums that you request. Single tracks, playlist tracks and flow tracks need another download source, such as the built-in yt-dlp or slskd. See [Lidarr](https://docs.aurral.org/integrations/lidarr/).

## Installation

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)

   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)

2. Install this add-on.
3. Click the `Save` button to store your configuration.
4. Set the `download_folder` option to your preferred path.
5. Start the add-on.
6. Check the logs of the add-on to see if everything went well.
7. Open the webUI and complete onboarding.
