 
## 1.5.3 (2026-08-29)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)
 
## 1.5.2 (2026-08-22)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)
 
## 1.5.1.2 (2026-08-19)
- Fix direct access on port 8071, which was broken in 1.5.1.1: the root
  redirect pointed at the container-internal port 8072 instead of the
  published one, and the page it led to referenced assets under a path the
  add-on did not serve, so every asset returned 404. Requests are now passed
  through unchanged, with the bare root and the two previously documented
  `/filebrowser_quantum` URLs redirected to the app's configured base path.

## 1.5.1.1 (2026-08-16)
- Expose the web UI on host port 8071, reachable at `<your-ip>:8071`
  (redirects to `/filebrowser_quantum/`). Direct access is served by a new,
  separate nginx vhost that proxies to the same backend Ingress already uses;
  Ingress itself, and the app's own base URL, are unchanged.

## 1.5.1 (2026-08-08)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)
 
## 1.5.0 (2026-07-22)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)
## 1.4.0-2 (16-07-2026)
- Minor bugs fixed
 
## 1.4.0 (2026-06-20)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)
## 1.3.3-8 (2026-06-03)
- Add `default_user_scope` option: sets the FileBrowser source path and default user scope (must be an existing absolute directory path, defaults to `/`)

- Allow config persistence

## 1.3.3 (2026-05-19)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.3.2 (2026-05-16)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.3.1 (2026-05-02)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.3.0 (2026-04-23)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.2.4 (2026-04-04)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.2.3 (2026-03-28)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.2.2 (2026-03-14)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.2.1 (2026-02-28)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.1.3 (2026-02-23)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.1.2 (2026-02-14)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.1.1 (2026-01-13)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.1.0 (2026-01-10)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.1.6b0 (2026-01-08)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.1.5b0 (2026-01-03)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)

## 1.2.0 (2025-12-28)
- Update to latest version from gtsteffaniak/filebrowser (changelog : https://github.com/gtsteffaniak/filebrowser/releases)
# Changelog

## 1.1.0
- Initial FileBrowser Quantum add-on.
