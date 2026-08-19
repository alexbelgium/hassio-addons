## 1.3.1 (19-08-2026)

- Initial release, based on upstream Kapowarr 1.3.1
- Home Assistant ingress support: Kapowarr is started with `--UrlBase /kapowarr` and nginx rewrites
  that prefix onto the ingress path, so the sidebar panel works without any user configuration
- Database and logs stored in the add-on configuration directory, so they survive updates
- Temporary downloads redirected to persistent storage (`/config/temp_downloads`)
- `PUID`/`PGID`, `TZ`, `env_vars`, local disk and SMB share mounting supported
