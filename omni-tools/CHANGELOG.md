## 0.6.1.2 (2026-09-07)
- Rebuild to pick up a shared `ha_entrypoint.sh` fix: the SIGTERM/SIGINT handler is now installed at the top of the entrypoint instead of at the end of startup. With `init: false` the entrypoint is namespace PID 1, and the kernel discards a signal that PID 1 has no handler for, so a stop arriving while the Supervisor probe or the `cont-init.d` chain was still running was lost entirely and the add-on died only when the grace period expired into SIGKILL. Stops are now honoured from the first moment of startup. No change to add-on behaviour otherwise.

## 0.6.1.1 (2026-09-07)
- Fix the add-on refusing to stop: Home Assistant reported an Error status after a few seconds and the container kept running and serving the web UI. `cont-init.d/99-run.sh` started nginx in the foreground, and `ha_entrypoint.sh` runs every cont-init script in the foreground, so the entrypoint never reached the point where it installs the `terminate()` handler that forwards SIGTERM to the application on shutdown. The application is now started in the background, and `init: false` makes the entrypoint run as PID 1 so the orphaned process is reparented to it and receives that signal. Closes #3049.


## 0.6.1 (2025-11-18)
- Added `env_vars` option to allow passing custom environment variables from the add-on configuration.

## 0.6.0 (2025-10-04)
- Update to latest version from iib0011/omni-tools (changelog : https://github.com/iib0011/omni-tools/releases)
## v0.5.0 (2025-07-30)
- Minor bugs fixed
## 0.5.0 (2025-07-30)
- Minor bugs fixed
# Changelog

## 1.0.0

- Initial release
- Based on omni-tools docker image iib0011/omni-tools:latest
- Self-hosted web application with various online utilities
- Client-side processing for privacy and security
- Features image, video, PDF, text, date/time, math, and data tools