## 1.3.1.1 (28-10-2026)

- Use the `bashio::app.*` functions instead of the deprecated `bashio::addon.*` ones, removing the deprecation warnings in the log; bashio older than v0.18.0 is upgraded to v0.19.0 at build time

## 1.3.1 (19-08-2026)

- Initial release, based on upstream Kapowarr 1.3.1
- Home Assistant ingress support: Kapowarr is started with `--UrlBase /kapowarr` and nginx rewrites
  that prefix onto the ingress path, so the sidebar panel works without any user configuration
- The host, port and URL base are re-applied on every start, so a hosting setting changed by hand
  in the web interface is repaired by restarting the add-on rather than breaking it permanently
- Database and logs stored in the add-on configuration directory, so they survive updates
- Temporary downloads redirected to persistent storage (`/config/temp_downloads`)
- `PUID`/`PGID`, `TZ`, `env_vars`, local disk and SMB share mounting supported
