- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 2.2.2-1 (09-01-2026)
- ⚠ MAJOR CHANGE : switch to the new config logic from homeassistant. Your configuration files will have migrated from /config/addons_config/kometa to a folder only accessible from my Filebrowser addon called /addon_configs/xxx-kometa. Please make a backup before updating.
