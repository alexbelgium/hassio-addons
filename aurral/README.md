# Aurral

[Aurral](https://github.com/lklynet/aurral) is a self-hosted music discovery, request management, flows, and playlist importing app for Lidarr with library-aware recommendations.
This addon is based on the docker image <https://github.com/lklynet/aurral>

## Configuration

| Option | Default | Description |
|---|---|---|
| `download_folder` | `/share/aurral/downloads` | Path where Aurral writes flow downloads. Must be under `/share`. |
| `weekly_flow_folder` | `weekly-flow` | Subfolder name appended to `download_folder` for weekly flow files. The full path will be `download_folder/weekly_flow_folder`. |

## Installation

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)

   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)

2. Install this add-on.
3. Click the `Save` button to store your configuration.
4. Set the `download_folder` option to your preferred path.
5. Optionally set `weekly_flow_folder` to customise the weekly flow subfolder name.
6. Start the add-on.
7. Check the logs of the add-on to see if everything went well.
8. Open the webUI and complete onboarding.
