## source-20260705-2 (05-07-2026)
- Fix detections/database not persisting across restarts on a fresh install: upstream's default `config.yaml` ships `output.sqlite.path: birdnet.db` (relative) explicitly, so the missing-only (`//=`) seeding introduced previously never rewrote it to an absolute path. A relative path resolves against the app's ephemeral working directory, so the database was silently recreated empty on every restart. Any relative `output.sqlite.path` is now rewritten to live under the persistent `/config` on startup; values already set to an absolute path are left untouched. (https://github.com/tphakala/birdnet-go/discussions/3774)

## source-20260705 (05-07-2026)
- Minor bugs fixed
## source-2026070 (05-07-2026)
- Minor bugs fixed
## source-20260703 (03-07-2026)
- Minor bugs fixed
## source-20260702-em (02-07-2026)
- Minor bugs fixed
## source-20260702-2 (02-07-2026)
- Minor bugs fixed
## source-20260701 (01-07-2026)
- Minor bugs fixed
## source-20260629-3 (29-06-2026)
- Minor bugs fixed
## source-20260629-2 (29-06-2026)
- Minor bugs fixed
## source-20260629 (29-06-2026)
- Minor bugs fixed
## source-20260627-v3 (28-06-2026)
- Minor bugs fixed
## source-20260627-v2 (27-06-2026)
- Minor bugs fixed
## source-20260627 (27-06-2026)
- Minor bugs fixed
## source-20260626-5 (26-06-2026)
- Minor bugs fixed
## source-20260626-4 (26-06-2026)
- Minor bugs fixed
## source-20260626-3 (26-06-2026)
- Minor bugs fixed
## source-20260626 (26-06-2026)
- Minor bugs fixed
## source-20260625-14 (26-06-2026)
- Minor bugs fixed
## source-20260625-13 (25-06-2026)
- Minor bugs fixed
## source-20260625-12 (25-06-2026)
- Minor bugs fixed
## source-20260625-11 (25-06-2026)
- Minor bugs fixed
## source-20260625-10 (25-06-2026)
- Minor bugs fixed
## source-20260625-5 (25-06-2026)
- Minor bugs fixed
## source-20260625-4 (25-06-2026)
- Minor bugs fixed
## source-20260625-3 (25-06-2026)
- Minor bugs fixed
## source-20260625-2 (25-06-2026)
- Minor bugs fixed
## source-20260625 (25-06-2026)
- Minor bugs fixed
## source-20260624-6 (24-06-2026)
- Minor bugs fixed
## source-20260624-5 (24-06-2026)
- Minor bugs fixed
## source-20260624-4 (24-06-2026)
- Minor bugs fixed
## source-20260624-3 (24-06-2026)
- Minor bugs fixed
## source-20260624-2 (24-06-2026)
- Minor bugs fixed
## source-20260623-3 (23-06-2026)
- Minor bugs fixed
## source-20260623-2 (23-06-2026)
- Minor bugs fixed
## source-20260623 (23-06-2026)
- Minor bugs fixed
## source-20260622 (23-06-2026)
- Minor bugs fixed
## source-20260621-5 (22-06-2026)
- Minor bugs fixed
## source-20260621-4 (22-06-2026)
- Minor bugs fixed
## source-20260621-3 (22-06-2026)
- Minor bugs fixed
## source-20260621-2 (22-06-2026)
- Minor bugs fixed
## source-20260621-1 (21-06-2026)
- Fix OpenVINO load failure: bundle oneTBB (libtbb.so.12) from OpenVINO 3rdparty libs so libopenvino_c.so resolves at runtime
## source-20260620-13 (21-06-2026)
- Minor bugs fixed
## source-20260620-12 (21-06-2026)
- Minor bugs fixed
## source-20260620-11 (21-06-2026)
- Minor bugs fixed
## source-20260620-10 (21-06-2026)
- Minor bugs fixed
## source-20260620-7 (21-06-2026)
- Minor bugs fixed
## source-20260620-6 (21-06-2026)
- Minor bugs fixed
## source-20260620-5 (21-06-2026)
- Minor bugs fixed
## source-20260620-4 (21-06-2026)
- Minor bugs fixed
## source-20260620-3 (21-06-2026)
- Minor bugs fixed
## source-20260620-2 (21-06-2026)
- Minor bugs fixed
## source-20260620 (21-06-2026)
- Minor bugs fixed
## source-20260619-8 (20-06-2026)
- Minor bugs fixed
## source-20260619-7 (20-06-2026)
- Minor bugs fixed
## source-20260619-6 (20-06-2026)
- Minor bugs fixed
## source-20260619-5 (20-06-2026)
- Minor bugs fixed
## source-20260619-4 (20-06-2026)
- Minor bugs fixed
## source-20260619-3 (20-06-2026)
- Minor bugs fixed
## source-20260619-2 (20-06-2026)
- Minor bugs fixed
## source-20260619 (20-06-2026)
- Minor bugs fixed
## source-20260618-3 (18-06-2026)
- Minor bugs fixed
## source-20260618-2 (18-06-2026)
- Minor bugs fixed
## source-20260617-4 (18-06-2026)
- Minor bugs fixed
## source-20260617-3 (17-06-2026)
- Minor bugs fixed
## source-20260617-2 (17-06-2026)
- Minor bugs fixed
## source-20260617 (17-06-2026)
- Minor bugs fixed
## source-20260616-2 (16-06-2026)
- Minor bugs fixed
## source-20260616 (16-06-2026)
- Minor bugs fixed
## source-20260615bats (15-06-2026)
- Minor bugs fixed
## source-20260615 (15-06-2026)
- Minor bugs fixed
## source-20260614-2 (14-06-2026)
- Minor bugs fixed
## source-20260614 (14-06-2026)
- Minor bugs fixed
## source-20260613 (13-06-2026)
- Minor bugs fixed
## source-20260612-4 (13-06-2026)
- Minor bugs fixed
## source-20260612-3 (12-06-2026)
- Minor bugs fixed
## source-20260612-2 (12-06-2026)
- Minor bugs fixed
## source-20260612 (12-06-2026)
- Minor bugs fixed
## source-20260610-9 (11-06-2026)
- Minor bugs fixed
## source-20260610-8 (11-06-2026)
- Minor bugs fixed
## source-20260610-7 (11-06-2026)
- Minor bugs fixed
## source-20260610-6 (11-06-2026)
- Minor bugs fixed
## source-20260610-5 (11-06-2026)
- Minor bugs fixed
## source-20260610-4 (10-06-2026)
- Minor bugs fixed
## source-20260610-3 (10-06-2026)
- Minor bugs fixed
## source-20260610-2 (10-06-2026)
- Minor bugs fixed
## source-20260610 (10-06-2026)
- Minor bugs fixed
## source-20260608-8 (09-06-2026)
- Minor bugs fixed
## source-20260608-7 (09-06-2026)
- Minor bugs fixed
## source-20260608-6 (08-06-2026)
- Minor bugs fixed
## source-20260608-5 (08-06-2026)
- Minor bugs fixed
## source-20260608-4 (08-06-2026)
- Minor bugs fixed
## source-20260608-3 (08-06-2026)
- Minor bugs fixed
## source-20260608-2 (08-06-2026)
- Minor bugs fixed
## source-20260608 (08-06-2026)
- Minor bugs fixed
## source-20260607-4 (07-06-2026)
- Minor bugs fixed
## source-20260607-3 (07-06-2026)
- Minor bugs fixed
## source-20260607-2 (07-06-2026)
- Minor bugs fixed
## source-20260607 (07-06-2026)
- **Test variant** of the birdnet-go add-on that compiles BirdNET-Go from the `alexbelgium/birdnet-go` fork instead of pulling the prebuilt `ghcr.io/tphakala/birdnet-go` image.
- At build time, `merge-prs.sh` syncs the fork's `main` with the `tphakala/birdnet-go` upstream and merges every open non-draft ("in review") pull request on the fly, so the resulting binary is upstream main + all work currently under review.
- Home Assistant integration layers (nginx ingress, modules, init scripts, options handling) are identical to the standard birdnet-go add-on.
- Published as a separate image (`ghcr.io/alexbelgium/birdnet-go-source-{arch}`) so it never overwrites the production add-on image.
- Fix (`01-structure.sh`): create the absolute `BIRDSONGS_FOLDER` target (e.g. the default `/config/clips`) before migrating clips from a legacy `/data/clips`, so upgrades with existing recordings no longer abort startup under `set -e`.

## nightly-20260601-2 (03-06-2026)
- Minor bugs fixed
## nightly-20260601 (2026-06-01)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)
## nightly-20260524 (2026-05-30)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)
## nightly-20260429-405 (2026-05-30)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)
## nightly-20260525-3 (28-05-2026)
- New `mqtt_auto_config` addon option (default `false`). When `true` and the Home Assistant MQTT addon is active, `realtime.mqtt.{enabled,broker,username,password}` are written directly to `config.yaml` on every restart. When `false` but Mosquitto is detected, the addon still logs the broker details and reminds you about the option — nothing is written.
- New `mariadb_auto_config` addon option (default `false`). When `true` and the Home Assistant MariaDB addon is active, `output.mysql.*` is filled in and `output.sqlite.enabled` is set to `false`. When `false` but MariaDB is detected, the addon logs the credentials and reminds you about the option.
- **Breaking**: `output.sqlite.path` and `logging.file_output.*` are now seeded only when missing from `config.yaml` (previously overwritten every restart). Values changed through the BirdNET-Go UI or by hand-editing `config.yaml` now survive container restarts. If you relied on `LOG_MAX_SIZE_MB` / `LOG_MAX_AGE_DAYS` addon options to override an existing setting in `config.yaml`, remove the existing key from `config.yaml` or edit it directly — the option will only be applied on first run.
- **Breaking (UI only)**: The nginx ingress reverse-proxy no longer rewrites HTML `href`/`src`/`action` attributes; upstream BirdNET-Go handles those itself via `X-Ingress-Path`. JavaScript string-literal rewrites are unchanged. Please file an issue if you see broken images, links, or forms in the ingress UI after upgrade.
- Fix database-migration restore: the timestamped backup created during a `BIRDSONGS_FOLDER` change was being written to the script's working directory and looked up under a fresh timestamp on restore, so a SQL failure left the user unable to recover. Backup path is now absolute and reused for restore.
- Harden the `BIRDSONGS_FOLDER` SQL/YAML path substitution: paths containing characters outside `[A-Za-z0-9._/-]` are now rejected up front instead of being interpolated raw into the SQL UPDATE statement.
- Tolerate a missing internet connection on first boot: if the default `config.yaml` cannot be downloaded from GitHub, the init script now seeds an empty YAML document so the addon-defaults block populates a usable config (rather than aborting the script on the next `yq` call under `set -e`).
- Warn (without failing the build) if the upstream `entrypoint.sh` patch target drifts in a new nightly.
- Remove a dead nginx upstream definition that pointed at an unused port.

## nightly-20260525-2 (26-05-2026)
- Suppress noisy startup logs: silence `chmod /dev/snd` errors on the read-only HA mount, and hide unavailable ALSA plugins (JACK, OSS, dsnoop) from device enumeration so libjack and pcm_oss/dsnoop probes no longer print at launch. ALSA overrides are written to `/root/.asoundrc` (since `/etc/asound.conf` is read-only in this environment).
- Allow advanced users to override the ALSA config by dropping a custom `asound.conf` into the addon config folder.
- Add LOG_MAX_SIZE_MB and LOG_MAX_AGE_DAYS addon options to manage log storage size
- Automatically trim log files exceeding configured age on startup

## nightly-20260525 (26-05-2026)
- Minor bugs fixed

## nightly-20260511-414-2 (22-05-2026)
- Minor bugs fixed

## nightly-20260511-414 (2026-05-16)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20260429-405 (2026-05-02)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20260321-397 (2026-03-26)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20260315 (2026-03-21)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20260311 (2026-03-14)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)
## nightly-20260118-2 (17-02-2026)
- Minor bugs fixed

## nightly-20260118 (2026-01-21)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20260113 (2026-01-14)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20260111 (2026-01-12)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20260110 (2026-01-10)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)
## nightly-20251223-2 (2025-12-27)
- Minor bugs fixed
## nightly-20251224 (2025-12-24)
- Minor bugs fixed

## nightly-20251223 (2025-12-23)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20251214 (2025-12-20)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

- Preserve the microphone selected in the BirdNET-Go UI unless the `homeassistant_microphone` option explicitly forces the default device.

## "nightly-20251028" (2025-11-01)
- Minor bugs fixed

## nightly-20251028 (2025-11-01)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)
## "nightly-20251012" (2025-10-18)
- Minor bugs fixed

## nightly-20251012 (2025-10-18)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20251008 (2025-10-11)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)
## nightly-20250904_6 (2025-09-17)
- New option "homeassistant_microphone". If set to true, will use homeassistant's microphone by setting the audio_card to "default". Please use the addon options to select the device to which "default" is allocated

## nightly-20250904 (2025-09-06)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20250826 (2025-08-30)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20250813 (2025-08-16)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20250805 (2025-08-09)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)
## nightly-20250731-4 (2025-08-04)
- Minor bugs fixed
## nightly-20250731-3 (2025-08-04)
- Minor bugs fixed
## nightly-20250731-2 (2025-08-02)
- Minor bugs fixed

## nightly-20250731 (2025-08-01)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)
## nightly-20250730 (2025-07-30)
- Minor bugs fixed
## nightly-20250725-2 (2025-07-28)
- Fix /asset path
- Added 9090 telemetry port

## nightly-20250725 (2025-07-25)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## nightly-20250710 (2025-07-12)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 20250710 (2025-07-12)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 20250704 (2025-07-07)

- Minor bugs fixed

## 20250508 (2025-07-05)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 20250419 (2025-05-17)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 20250427-7 (2025-05-15)

- Breaking change: COMMAND addon option removed. Please instead use the config.yaml to define the RTSP feeds
- Use entrypoint

## 20250427-2 (2025-04-27)

- Minor bugs fixed

## 20250427 (2025-04-27)

- Minor bugs fixed

## 20250316 (2025-04-26)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 0.6.4-3 (2025-04-07)

- Minor bugs fixed

## 0.6.4-2 (2025-03-30)

- Minor bugs fixed

## 0.6.4 (2025-03-17)

- Minor bugs fixed

## 0.6.3 (2025-03-15)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 0.6.2-2 (2025-02-21)

- Minor bugs fixed

## 0.6.2 (2025-02-21)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 20250126-2 (2025-02-21)

- Minor bugs fixed

## 20250126 (2025-02-15)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 0.6.0-nightly-20250124 (2025-01-25)

- Minor bugs fixed

## 0.6.0-4 (2025-01-21)

- Fix sounds play
- Correct sqlite for //

## 0.6.0 (2025-01-18)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 20250103-10 (2025-01-17)

- BREAKING CHANGE : improve implementation of addon options such as Birdsongs folder. Please check the log at first start if anything is different than you expected
- WARNING : your files will move to the new Birdsongs folder in case of change
- WARNING : your db will be modified in case of Birdsongs folder change to still allow access to files. A backup will always be created
- Fix ingress issues

## 20250103 (2025-01-11)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 25-4 (2024-12-29)

- Fixed https://github.com/alexbelgium/hassio-addons/issues/1687

## 25-3 (2024-12-28)

- avx2 support added by @tphakala

## 25-2 (2024-12-21)

- Minor bugs fixed

## 25 (2024-12-21)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 0.5.5-11 (2024-10-22)

- Minor bugs fixed

## 0.5.5-10 (2024-09-30)

- Minor bugs fixed

## 0.5.5-9 (2024-07-06)

- Correct indentation issue

## 0.5.5-8 (2024-07-03)

- New option : set the audio clip directory from addon options

## 0.5.5-2 (2024-06-25)

- Minor bugs fixed

## 0.5.5 (2024-06-22)

- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)

## 0.5.5 (2024-06-20)

- Minor bugs fixed

## 0.5.3-3 (2024-06-07)

- Minor bugs fixed

## 0.5.3-2 (2024-06-07)

- Minor bugs fixed

## 0.5.3 (2024-05-26)

- Minor bugs fixed

## 0.5.2 (2024-05-04)

- Minor bugs fixed

## 0.5.1-4 (2024-04-23)

- Feat : provide mariadb information in the startup log to allow its usage

## 0.5.1-3 (2024-04-23)

- Feat : Allow mounting of SMB and local drives to store the audio clips on an external drive

## 0.5.1 (2024-04-22)

- Initial build
