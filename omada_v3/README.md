# Home assistant add-on: Omada v3

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fomada_v3%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fomada_v3%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fomada_v3%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/omada_v3/stats.png)

## ⚠️ Migration Notice

**This legacy addon (v3) is no longer actively maintained.**

**Recommendation:** Please backup your database and migrate to this dedicated addon: https://github.com/jkunczik/home-assistant-omada

The recommended alternative:
- Is dedicated to Omada functionality  
- Is in active development
- Should be more stable and feature-complete
- Has better community support
- Supports newer Omada Controller versions

## About

This addon provided the legacy TP-Link Omada Controller v3.x for managing older TP-Link Omada networking equipment. This version is deprecated and should only be used for legacy systems that cannot be upgraded.

**Note:** This is the legacy v3 version. Consider migrating to the current Omada addon or the recommended third-party addon for better performance and support.

## Migration Instructions

**For Legacy Systems (v3):**
1. Backup your current v3 configuration
2. Consider upgrading your Omada devices to support newer controller versions
3. Migrate to the recommended addon: https://github.com/jkunczik/home-assistant-omada

**Migration Path:**
1. **Backup current data** from your v3 controller
2. **Install recommended addon** from the third-party repository
3. **Import configuration** and reconnect devices
4. **Verify functionality** before removing this legacy addon

## Legacy Support

This addon is maintained for compatibility only. No new features will be added.

For support with migration or the recommended replacement: Visit https://github.com/jkunczik/home-assistant-omada

[repository]: https://github.com/alexbelgium/hassio-addons
