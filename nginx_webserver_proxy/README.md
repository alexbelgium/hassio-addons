# Nginx Proxy Manager + Static Web Server

[Nginx Proxy Manager](https://nginxproxymanager.com/) with a configurable static file server for Home Assistant. Manage reverse proxies and SSL certificates via the web UI (port 81) while serving static files from your HA storage (port 80).

## Why This Add-on?

Home Assistant's built-in folder server has limitations:
- Can only serve from a single folder at a time
- No reverse proxy capabilities
- No SSL/HTTPS support
- Limited HTTP headers and caching control
- No support for URL rewriting or advanced routing

This add-on combines a full reverse proxy with a proper static file server, allowing you to host multiple sites, manage SSL certificates, and proxy traffic to other services from a single interface.

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)

## Features

- Reverse proxy manager (web UI on port 81)
- Static file server (port 80)
- HTTPS support (port 443)
- Persistent configuration and SSL certificates
- Works on amd64 and aarch64

## Installation

1. Add this repository to Home Assistant via Settings → Add-ons → Add-on Store → ⋮ → Manage repositories (or use the button above).
2. Install Nginx Proxy Manager + Static Web Server.
3. Configure options (defaults work for first run).
4. Start the add-on.
5. Open `http://<HA_IP>:81` to access the admin UI.

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `static_site_enabled` | `true` | Enable or disable the static file server on port 80 |
| `static_site_root` | `/share/www` | Path to serve static files from |
| `static_site_prefix` | `/` | URL prefix for the static site (e.g., `/www` for `http://host/www`) |
| `log_level` | `info` | Logging verbosity: `info`, `debug`, `warn`, or `error` |

## Default Credentials

First login (port 81):
- Email: `admin@example.com`
- Password: `changeme`

Change these on first login.

## Path Validation

Paths are validated at startup for safe access:

- `/share`, `/media`, `/config` – fully supported (HA maps these automatically)
- `/mnt` – allowed but not mapped by HA. Create a symlink under `/share` or `/media` if files are inaccessible.
- `/`, `/etc`, `/bin`, `/lib`, `/proc`, `/sys` – blocked (will prevent startup)

## Examples

**Reverse proxy:**
1. Open the admin UI at `http://<HA_IP>:81`
2. Add a proxy host pointing to another service
3. Configure SSL via Let's Encrypt (optional)

**Static website:**
1. Place files in `/share/www` (or your configured `static_site_root`)
2. Access at `http://<HA_IP>:80/` (or your configured `static_site_prefix`)

You can run both simultaneously on the same ports.

## Notes

- Wraps `jc21/nginx-proxy-manager` upstream image
- State persists in `/data` (managed by HA Supervisor)
- Custom AppArmor profile restricts system access
- Edit NPM's database directly via SSH if needed

## Issues

For problems with this add-on (not the upstream NPM software), open an issue and tag @ToledoEM.
