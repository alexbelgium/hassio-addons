# Claude Desktop sign-in — shipped fixes and planned work

Two related sign-in problems when Claude Desktop runs inside the LinuxServer Selkies
streamed desktop.

**Status:**
- **Shipped:** Problem B (sign-in persistence) — the `autostart` bootstrap landed in v1.4, and
  the `gnome-keyring` package itself was added in v1.17. That approach was later reverted:
  v1.24-ish removed `gnome-keyring` again because it prompts for a keyring password on first
  boot, which blocked Claude Desktop from ever launching — but the launch flag was left
  forcing the now-daemonless libsecret backend, so `safeStorage` silently went unavailable
  again (recurring "sign in again", and — new in this round — the Claude app's dispatch tab
  showing the desktop as offline until a fresh sign-in was done from a computer). Fixed in
  v1.35: switched to `--password-store=basic` (Electron's built-in store, no keyring
  involved at all) plus a cont-init script that re-syncs the persistent openbox `autostart`
  from the image on every boot, so the fix reaches existing installs, not just fresh ones.
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
- Add the two `xdg-settings`/`xdg-mime` commands to the custom script
  `/addon_configs/db21ed7f_claude-desktop/claude_desktop.sh` (the image ships no standalone
  terminal).

---

## Problem B — "Your sign-in won't be saved on this device" / recurring re-auth / dispatch shows offline

Symptoms (all three are the same root cause):
- > Install and unlock a system keyring (such as GNOME Keyring), then restart the app.
- Periodic **"For your security, sign in again to keep using Claude."**
- The Claude app's dispatch tab shows this desktop as **not online**, even though the
  process is running — until a fresh sign-in is completed from a computer.

### Root cause (history)
Claude Desktop (Electron) persists its auth token with `safeStorage`, which on Linux
encrypts via the **Secret Service API** (`org.freedesktop.secrets`) provided by
gnome-keyring/kwallet. `--password-store=gnome-libsecret` **forces** that backend.

This was fixed once (v1.17: `gnome-keyring` added to the Dockerfile) and then regressed:
`gnome-keyring` was later removed again because, on first boot, it prompts for a keyring
password and **blocks Claude Desktop from launching at all** — a worse failure than a lost
session. The launch flag was left forcing libsecret, so with no daemon running
`safeStorage.isEncryptionAvailable()` is `false`. Confirmed from a live install's
`~/.config/Claude/logs/main.log`:
```
[safeStorage] isEncryptionAvailable=false ... (backend=gnome_libsecret) — session will not persist; app secrets fall back to plaintext
Electron safeStorage encryption is not available on this system, cannot store allowlist cache
```
The un-persisted session goes stale and then fails the elevated-access OAuth check the
cowork/dispatch bridge needs:
```
permission_error: "Session is not fresh enough to grant elevated access. Sign in again to continue." (session_stale_relogin)
[sessions-bridge] Cowork OAuth stale-session (session_stale_relogin); parking bridge until re-login
```
That "parked" bridge is exactly what the Claude app surfaces as this desktop being
**offline** in the dispatch tab — a fresh sign-in (only completable from a computer, see
Problem A) un-parks it, which is why "open from a computer first" appeared to fix it.

Re-adding gnome-keyring would just reintroduce the original launch-blocking prompt, so it's
a dead end without also solving *that* — hence the shipped fix below avoids keyring
entirely.

### Fix (shipped, v1.35)
1. `claude_desktop/rootfs/defaults/autostart` launches with
   `--password-store=basic` instead of `gnome-libsecret`. `basic` is Electron's built-in
   fixed-key store: `isEncryptionAvailable()` is always `true`, no daemon, no prompt. Secrets
   land under `$HOME/.config/Claude`, and `HOME=/data/data` is persistent add-on storage, so
   the session survives restarts.
2. A passwordless keyring was considered instead (keeps libsecret encryption-at-rest without
   a prompt) and rejected: the keyring DB would live in the same persistent volume as the
   ciphertext it's "protecting," so it adds ~no real confidentiality in this single-user
   self-hosted setup, for more moving parts than `basic`.
3. `claude_desktop/rootfs/etc/cont-init.d/85-openbox_autostart.sh` (new): the app is actually
   launched from the **persistent** `$HOME/.config/openbox/autostart`, which the base image's
   `init-selkies-config` oneshot only seeds from `/defaults/autostart` when the persistent
   copy is *missing*. Editing `/defaults/autostart` alone therefore never reaches an existing
   install's copy. This script re-syncs the persistent copy from the image on every boot (as
   root, before any s6-rc service starts), so this fix — and any future `autostart` change —
   reaches upgrades, not just fresh installs.
4. `gnome-keyring` stays out of the Dockerfile.

### One-time step after upgrading
The previously-stored session is already stale. Complete **one** sign-in from a computer
(mobile still can't finish the OAuth flow itself, per Problem A) — the session then persists
normally and dispatch stays online regardless of which device connects first afterward.

---

## Files this plan touched
- `claude_desktop/rootfs/defaults/autostart` — drop the keyring bootstrap; launch with
  `--password-store=basic`.
- `claude_desktop/rootfs/etc/cont-init.d/85-openbox_autostart.sh` — new; syncs the persistent
  autostart from the image on every boot.
- `claude_desktop/Dockerfile` — corrected stale comment (gnome-keyring is not installed).
- `claude_desktop/CHANGELOG.md` / `config.yaml` — v1.35.

Problem A (in-desktop browser for OAuth) remains planned-only; not touched by this change.
