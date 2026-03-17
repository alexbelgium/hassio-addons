# Home assistant add-on: Immich Frame


I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fimmich_frame%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fimmich_frame%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fimmich_frame%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/immich_frame/stats.png)

## About

[Immich Frame](https://immichframe.online/) displays your Immich gallery as a digital photo frame. Transform any screen into a beautiful, rotating display of your personal photos and memories stored in Immich.

This addon allows you to create a digital photo frame that connects to your Immich server and displays your photos in a slideshow format, perfect for repurposing old tablets or monitors as dedicated photo displays.

## Configuration

Webui can be found at `<your-ip>:8171`.

### Options

#### Connection

| Option | Type | Description |
|--------|------|-------------|
| `ImmichServerUrl` | str | URL of your Immich server (e.g., `http://homeassistant:3001`). Used for single-account setup. |
| `ApiKey` | str | Immich API key for authentication. Used for single-account setup. |
| `Accounts` | list | List of Immich accounts for multi-account support. Each entry requires `ImmichServerUrl` and `ApiKey`, plus optional per-account filters (see below). |
| `TZ` | str | Timezone (e.g., `Europe/London`) |

#### General (Display) Options

These top-level options map to ImmichFrame's `General` settings and control the display behavior:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Interval` | int | 45 | Image display interval in seconds |
| `TransitionDuration` | float | 2 | Transition duration in seconds |
| `ShowClock` | bool | true | Display the current time |
| `ClockFormat` | str | `hh:mm` | Time format for the clock |
| `ClockDateFormat` | str | `eee, MMM d` | Date format for the clock |
| `ShowProgressBar` | bool | true | Display the progress bar |
| `ShowPhotoDate` | bool | true | Display the date of the current image |
| `PhotoDateFormat` | str | `MM/dd/yyyy` | Date format for photo dates |
| `ShowImageDesc` | bool | true | Display image description |
| `ShowPeopleDesc` | bool | true | Display people names |
| `ShowTagsDesc` | bool | true | Display tag names |
| `ShowAlbumName` | bool | true | Display album names |
| `ShowImageLocation` | bool | true | Display image location |
| `ShowWeatherDescription` | bool | true | Display weather description |
| `ImageZoom` | bool | true | Zoom into images for a touch of life |
| `ImagePan` | bool | false | Pan images in a random direction |
| `ImageFill` | bool | false | Fill available space (may crop) |
| `PlayAudio` | bool | false | Play audio for videos with audio tracks |
| `PrimaryColor` | str | `#f5deb3` | Primary UI color (hex) |
| `SecondaryColor` | str | `#000000` | Secondary UI color (hex) |
| `Style` | str | `none` | Background style: `none`, `solid`, `transition`, `blur` |
| `Layout` | str | `splitview` | Layout: `single` or `splitview` |
| `BaseFontSize` | str | `17px` | Base font size (CSS format) |
| `Language` | str | `en` | 2-digit ISO language code |
| `WeatherApiKey` | str | | OpenWeatherMap API key |
| `UnitSystem` | str | `imperial` | `imperial` or `metric` |
| `WeatherLatLong` | str | | Weather location as `lat,lon` |
| `ImageLocationFormat` | str | `City,State,Country` | Location display format |
| `DownloadImages` | bool | false | Download images to server |
| `RenewImagesDuration` | int | 30 | Re-download images after this many days |
| `RefreshAlbumPeopleInterval` | int | 12 | Hours between album/people refresh |

#### Per-Account Options

These options can be set within each `Accounts` entry to control which images are shown:

| Option | Type | Description |
|--------|------|-------------|
| `Albums` | str | Comma-separated album UUIDs |
| `ExcludedAlbums` | str | Comma-separated excluded album UUIDs |
| `People` | str | Comma-separated people UUIDs |
| `Tags` | str | Comma-separated tag paths (e.g., `Vacation,Travel/Europe`) |
| `ShowFavorites` | bool | Show favorite images |
| `ShowMemories` | bool | Show memory images |
| `ShowArchived` | bool | Show archived images |
| `ShowVideos` | bool | Include video assets |
| `ImagesFromDays` | int | Show images from the last X days |
| `ImagesFromDate` | str | Show images after this date |
| `ImagesUntilDate` | str | Show images before this date |
| `Rating` | int | Filter by star rating (-1 to 5) |

### Single Account Example

```yaml
ImmichServerUrl: "http://homeassistant:3001"
ApiKey: "your-immich-api-key-here"
TZ: "Europe/London"
ShowClock: false
Interval: 30
PhotoDateFormat: "dd/MM/yyyy"
```

### Multi-Account Example

To display photos from multiple Immich accounts (e.g., you and your partner), use the `Accounts` list:

```yaml
Accounts:
  - ImmichServerUrl: "http://homeassistant:3001"
    ApiKey: "api-key-for-user-1"
    Albums: "album-uuid-1,album-uuid-2"
    ShowFavorites: true
  - ImmichServerUrl: "http://homeassistant:3001"
    ApiKey: "api-key-for-user-2"
    People: "person-uuid-1,person-uuid-2"
ShowClock: false
Interval: 40
TZ: "Europe/London"
```

When using the `Accounts` list, the `ApiKey` and `ImmichServerUrl` top-level options are not needed. Images will be drawn from each account proportionally based on the total number of images present in each account.

For more configuration options, see the [ImmichFrame documentation](https://immichframe.dev/docs/getting-started/configuration).

### Getting Your Immich API Key

1. Open your Immich web interface
2. Go to **Administration** > **API Keys**
3. Click **Create API Key**
4. Give it a descriptive name (e.g., "Photo Frame")
5. Copy the generated API key and paste it in the addon configuration

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **env_vars option**: Use the add-on `env_vars` option to pass extra ImmichFrame settings not available in the addon UI. Environment variables are automatically classified as General or Account-level settings and written to `Settings.yaml`. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

**env_vars example** (for settings not in the UI):
```yaml
env_vars:
  - name: AuthenticationSecret
    value: "my-secret"
  - name: Webhook
    value: "http://example.com/notify"
```

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Configure your Immich server URL and API key.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI to configure your photo frame settings.

## Support

Create an issue on github, or ask on the [home assistant community forum](https://community.home-assistant.io/)

For more information about Immich Frame, visit: https://immichframe.online/

[repository]: https://github.com/alexbelgium/hassio-addons

