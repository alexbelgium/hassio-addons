# Home assistant add-on: Omada

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fomada%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fomada%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fomada%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/omada/stats.png)

## ⚠️ Migration Notice

**This addon is no longer actively maintained.**

**Recommendation:** Please backup your database and migrate to this dedicated addon: https://github.com/jkunczik/home-assistant-omada

The recommended alternative:
- Is dedicated to Omada functionality
- Is in active development
- Should be more stable and feature-complete
- Has better community support

## About

This addon provided the TP-Link Omada Controller for managing TP-Link Omada networking equipment including access points, switches, and routers through a centralized web interface.

The Omada Controller allows you to:
- Manage multiple TP-Link Omada devices
- Configure wireless networks and VLANs
- Monitor network performance and usage
- Set up guest networks and access controls
- Manage firmware updates
- Generate network reports

## Migration Instructions

1. **Backup your current data:**
   - Access your current Omada Controller
   - Export your configuration and settings
   - Note down all your network configurations

2. **Install the recommended addon:**
   - Add the repository: https://github.com/jkunczik/home-assistant-omada
   - Install the new Omada addon
   - Follow their setup instructions

3. **Import your data:**
   - Import your backed-up configuration
   - Verify all devices are properly connected
   - Test your network functionality

## Legacy Configuration

If you still need to use this addon temporarily:

Webui can be found at `<your-ip>:8088` (HTTP) or `<your-ip>:8043` (HTTPS).

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

## Support

For this legacy addon: Create an issue on github

For the recommended replacement: Visit https://github.com/jkunczik/home-assistant-omada

[repository]: https://github.com/alexbelgium/hassio-addons
