## 2026.10.28.1 (28-10-2026)
- Fix: restarting the services no longer leaves a previous `daily_plot.py` or recording loop running next to the new one. `restart_services.sh` now clears leftover `daily_plot.py`, `birdnet_recording.sh`, and `ffmpeg`/`arecord` recorders writing to `StreamData` once the recorder is stopped (port of the birdnet-pi fix for #3152)
- Fix: an unreachable audio source (RTSP host switched off, missing soundcard) no longer causes a restart loop with growing RAM. The monitoring service now reports the silent source instead of restarting when there is nothing queued to analyze, and limits the static `analyzing_now.txt` restart path to once every 30 minutes
- Fix: the recording retry loop no longer restarts `ffmpeg` once per second while the audio source is unreachable (100%+ CPU). The retry delay now grows from 1s to 64s, and resets once `ffmpeg` has run for more than two minutes
- The add-on's wrapper scripts (`custom-services.d`, `etc`, `helpers`) are now shared with birdnet-pi through symlinks, as battybirdnet-pi already does, so future birdnet-pi fixes reach this add-on too (#3154)
- Fix: the web UI (PHP-FPM, caddy) no longer waits for D-Bus to start, and creates `/run/php` itself; the timezone falls back to `TZ` when D-Bus is unavailable
- Fix: the ingress site is added to the Caddyfile only once (a duplicate `:8082` site makes caddy refuse to start), and `02-caddy.sh` re-adds it if `update_caddyfile.sh` dropped it

## 2026.10.28 (2026-10-28)
- Update to latest version from zach7036/BirdNET-Pi-Enhanced-Version (changelog : https://github.com/zach7036/BirdNET-Pi-Enhanced-Version/releases)
- Upstream tag : 2.8.4
- Local disks: `localdisks` can now mount a single folder of a disk with `disk/folder` (e.g. `sda1/public` or `NAS/public`, mounted at `/mnt/<disk>/<folder>`). Existing values are unchanged.
- Migrate legacy add-on configuration map names to current app configuration terminology.
## 2026.08.15 (15-08-2026)

- Fix: `ALSA_CARD` now really selects the microphone. Its value was copied as-is into `REC_CARD`, but BirdNET-Pi hands `REC_CARD` to `arecord -D` / `ffmpeg -f alsa -i`, which expect an ALSA PCM name: a card index such as `1` gave `Unknown PCM 1` and no recording at all. It is now converted to `plughw:CARD=<value>,DEV=0`, while a value that already is a PCM name (`dsnoop:CARD=Audio,DEV=0`, `default`, `null`, `pulse`, `pipewire`, ...) is used as provided
- Fix: setting `ALSA_CARD` no longer replaces the `~/BirdNET-Pi/birdnet.conf` symlink with a detached copy of `/config/birdnet.conf` (now only `/config/birdnet.conf`, which the symlink points to, is updated)

## 2026.07.10-2 (10-07-2026)
- Minor bugs fixed
## 2026.07.10 (10-07-2026)
- Initial release: BirdNET-Pi add-on based on the zach7036/BirdNET-Pi-Enhanced-Version fork
