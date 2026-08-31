 
## 1.5.3.3 (2026-08-31)
- Complete the iOS companion app fix from 1.5.3.2. The "no preview available"
  screen -- what you get for a `.zip`, `.bin` or anything else FileBrowser
  cannot render -- offers its Download and "Open file" buttons as new-tab
  links, and so does the share list in settings. The app hands every new tab
  to an external browser, which carries no ingress session, so those answered
  401. Those two buttons and the settings share links now stay in the panel
  when running in the companion app, and open a new tab as before in a normal
  browser -- as does a cmd/ctrl/shift-click anywhere, which is left alone.
  Download also saves the file instead of displaying it, which 1.5.3.2 only
  fixed for the download button in the file list. Links the app opens without
  a link element, such as the public-share sidebar download, are still
  affected.
 
## 1.5.3.2 (2026-08-30)
- Fix Download in the Home Assistant iOS companion app (iOS 17 and later),
  where a file opened and showed its content with no way to save it.
  FileBrowser downloads by clicking a link that carries no `download`
  attribute, and the app's WKWebView only turns a click into a real download
  when that attribute is present, so inside the ingress panel the file was
  simply rendered. The ingress filter now adds the attribute to FileBrowser's
  own download link. "Open file" still opens, and the public-share sidebar's
  own download button is not covered. Desktop browsers already downloaded
  these and are unchanged, as is direct access on port 8071.
 
## 1.5.3.1 (2026-08-29)
- Fix "open parent directory" in Tools -> File Size Analyzer under Home
  Assistant ingress. FileBrowser opened the parent folder in a new tab, which
  lands on the raw ingress URL with no Home Assistant frontend around it to
  keep the ingress session alive, so the new tab answered 401 instead of
  showing the folder. The ingress vhost now turns that popup into a navigation
  of the panel itself. The same fix covers the other tool views and the "go to
  item" action on search results, which open a new tab the same way. Download
  and preview popups, links pointing out of the add-on, and direct access on
  port 8071 are unchanged.
 
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
