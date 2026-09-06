## 1.3.2 (2026-09-06)
- Add `nfsversions` option: configure the NFS protocol versions tried when mounting NFS shares (comma or space separated, e.g. `4.2, 4.1, 4, 3`). Defaults to the previous built-in `4.2 4.1 4 3` ladder when unset, so existing installs are unchanged

## 1.3.1 (19-08-2026)

- Initial release, based on upstream Kapowarr 1.3.1
- Home Assistant ingress support: Kapowarr is started with `--UrlBase /kapowarr` and nginx rewrites
  that prefix onto the ingress path, so the sidebar panel works without any user configuration
- The host, port and URL base are re-applied on every start, so a hosting setting changed by hand
  in the web interface is repaired by restarting the add-on rather than breaking it permanently
- Database and logs stored in the add-on configuration directory, so they survive updates
- Temporary downloads redirected to persistent storage (`/config/temp_downloads`)
- `PUID`/`PGID`, `TZ`, `env_vars`, local disk and SMB share mounting supported
