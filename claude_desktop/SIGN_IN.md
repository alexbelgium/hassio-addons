# Claude Desktop sign-in — shipped fixes and planned work

Two related sign-in problems when Claude Desktop runs inside the LinuxServer Selkies
streamed desktop.

**Status:**
- **Shipped:** Problem B (keyring persistence) is implemented in v1.4 (Dockerfile + `rootfs/defaults/autostart`).
- **Planned only:** Problem A (in-desktop browser for OAuth) is intentionally not implemented.
  The image ships no browser; complete the login with the user-side workaround below.

---

## Problem A — Cannot complete login

Symptoms:
- **"Continue with Google"** does nothing.
- **"Continue with email"** sends a link that "must be opened from the same machine".

### Root cause
Claude Desktop signs in through an **external web page** (Google OAuth or the email magic
link) and then hands the token back to the app via the **`claude://` URL scheme**
(auto-registered on first launch). Both paths need:
1. a **web browser inside the streamed desktop** to render the auth page, and
2. a **default-browser association** so the app's `xdg-open <url>` call goes somewhere.

The Selkies base image ships **no browser** and no default handler, so `xdg-open` has
nothing to dispatch to → Google "does nothing", and the email link's final `claude://…`
redirect only works on the machine running the app (the container), which currently can't
render/handle it.

### Fix (image level)
In `claude_desktop/Dockerfile`, install a browser and register defaults so the whole flow
completes inside the session:
- `apt-get install -y --no-install-recommends chromium` (Debian bookworm package name;
  `firefox-esr` is an alternative).
- Set the default browser and confirm the scheme handlers, e.g. as an s6 oneshot or in the
  desktop `autostart` (runs as the session user with `$DISPLAY`/dbus available):
  ```sh
  xdg-settings set default-web-browser chromium.desktop
  xdg-mime default claude-desktop.desktop x-scheme-handler/claude
  ```
- Verifying expectations (for reference, not a test step):
  `x-scheme-handler/https` → `chromium.desktop`, `x-scheme-handler/claude` →
  `claude-desktop.desktop`.

Then login is done entirely in the streamed desktop: **Continue with Google** opens
Chromium in-session and the `claude://` redirect lands back in the app; or paste the email
magic link into the in-session Chromium (not a phone).

### User-side workaround (no rebuild)
- Add-on Configuration → `additional_apps: chromium`, restart (installed by
  `rootfs/etc/cont-init.d/80-configuration.sh`).
- Run the two `xdg-settings`/`xdg-mime` commands once in an in-session terminal, or add them
  to the custom script `/addon_configs/db21ed7f_claude-desktop/claude-desktop.sh`.

---

## Problem B — "Your sign-in won't be saved on this device"

Symptom:
> Install and unlock a system keyring (such as GNOME Keyring), then restart the app.

### Root cause
Claude Desktop (Electron) persists its auth token with `safeStorage`, which on Linux
encrypts via the **Secret Service API** (`org.freedesktop.secrets`) provided by
gnome-keyring/kwallet. The Selkies base runs only a **system** D-Bus
(`svc-dbus` → `dbus-daemon --system`) and has **no keyring daemon**, so `safeStorage` is
unavailable and the token cannot be stored → the app warns and forgets the session on
restart.

Note: the desktop itself already runs under a **session** bus —
`root/defaults/startwm.sh` launches `dbus-launch --exit-with-session openbox-session`, so
apps started from the openbox `autostart` inherit `DBUS_SESSION_BUS_ADDRESS`. The keyring
must be started **inside that session** so it registers the secrets service on the same bus
Claude Desktop uses. No extra `dbus-launch` is needed.

### Fix (image level)
1. `claude_desktop/Dockerfile`: install
   `gnome-keyring libsecret-1-0 dbus-x11` (dbus-x11 provides `dbus-launch`, already used by
   startwm; libsecret-1-0 is the backend Electron dlopens).
2. `claude_desktop/rootfs/defaults/autostart`: start & unlock an empty-password keyring
   before launching the app, and force the libsecret backend. Proposed content:
   ```sh
   # Start + unlock a gnome-keyring secrets service so Claude Desktop can persist sign-in.
   # Runs inside the openbox session's dbus (startwm.sh: dbus-launch --exit-with-session).
   eval "$(printf '' | gnome-keyring-daemon --login)" 2>/dev/null || true
   eval "$(gnome-keyring-daemon --start --components=secrets)" 2>/dev/null || true
   dbus-update-activation-environment --all >/dev/null 2>&1 || true

   claude-desktop --no-sandbox --disable-dev-shm-usage --password-store=gnome-libsecret
   ```
   - `--login` reads the password from stdin (empty here), creating and unlocking the login
     keyring on first run and starting the daemon in login mode; `--start --components=secrets`
     then exposes the Secret Service and exports `GNOME_KEYRING_CONTROL`/`SSH_AUTH_SOCK`.
   - `--password-store=gnome-libsecret` forces Electron to use the libsecret backend instead
     of falling back to plaintext.
3. Persistence: the keyring DB lives in `$HOME/.local/share/keyrings/` and `HOME=/config/data`
   (persistent add-on storage), so the empty-password login keyring survives restarts and is
   re-unlocked automatically each boot by the same `autostart` line — the sign-in then sticks.

### User-side workaround (no rebuild)
- Add-on Configuration → `additional_apps: gnome-keyring, libsecret-1-0, dbus-x11`, restart.
- Add the keyring-start lines above to the custom script
  `/addon_configs/db21ed7f_claude-desktop/claude-desktop.sh`, and relaunch Claude Desktop
  with `--password-store=gnome-libsecret` (e.g. edit the in-session openbox autostart).

---

## Files this plan would touch (when implemented)
- `claude_desktop/Dockerfile` — install `chromium`, `gnome-keyring`, `libsecret-1-0`,
  `dbus-x11`; set default browser + scheme handlers.
- `claude_desktop/rootfs/defaults/autostart` — keyring bootstrap + `--password-store` flag.
- `claude_desktop/CHANGELOG.md` / `config.yaml` version bump.

## Open questions before implementing
- Bundle **chromium** vs **firefox-esr** as the in-image browser?
- Empty-password keyring (fully unattended) vs. reuse the add-on `PASSWORD` option to lock
  the keyring with the same password?
