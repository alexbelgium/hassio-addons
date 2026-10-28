## 2026.10.28.1 (2026-10-28)

- Use the `bashio::app.*` functions instead of the deprecated `bashio::addon.*` ones, removing the deprecation warnings in the log; bashio older than v0.18.0 is upgraded to v0.19.0 at build time

 
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
