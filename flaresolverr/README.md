
# Home assistant add-on: Flaresolver

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fflaresolverr%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fflaresolverr%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fflaresolverr%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/flaresolverr/stats.png)

## About

[FlareSolverr](https://github.com/FlareSolverr/FlareSolverr) is a proxy server to bypass Cloudflare protection. It starts a proxy server that waits for user requests in an idle state using few resources. When a request arrives, it uses Puppeteer with the stealth plugin to create a headless browser (Firefox) that solves Cloudflare challenges.

Key features:
- Bypasses Cloudflare protection automatically
- Headless browser automation with Firefox
- RESTful API for integration with other tools
- Cookie extraction for subsequent requests
- Support for various Cloudflare challenge types

**Note**: Web browsers consume significant memory. Avoid making many concurrent requests on systems with limited RAM.

## Installation

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.

## Configuration

Web interface can be found at <http://homeassistant:8191>.
This addon has no configuration options - it works out of the box.

### API Usage

FlareSolverr provides a REST API for integration with other applications:

**Endpoint**: `http://homeassistant:8191/v1`

**Example Request**:
```json
{
  "cmd": "request.get",
  "url": "https://example.com",
  "maxTimeout": 60000
}
```

### Integration with *arr Apps

Configure your indexers to use FlareSolverr:
- **Prowlarr/Jackett**: Set FlareSolverr URL to `http://homeassistant:8191`
- **Sonarr/Radarr**: Configure indexers to use the FlareSolverr proxy

### Options

No configuration options are available - FlareSolverr works automatically with default settings.

### Resource Requirements

- **Memory**: 512MB+ recommended
- **CPU**: Moderate usage during challenge solving
- **Network**: Requires internet access to function

## Support

Create an issue on github

[repository]: https://github.com/alexbelgium/hassio-addons
