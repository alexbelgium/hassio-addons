## 2026.08.15 (15-08-2026)

- Fix: `ALSA_CARD` now really selects the microphone. Its value was copied as-is into `REC_CARD`, but BirdNET-Pi hands `REC_CARD` to `arecord -D` / `ffmpeg -f alsa -i`, which expect an ALSA PCM name: a card index such as `1` gave `Unknown PCM 1` and no recording at all. It is now converted to `plughw:CARD=<value>,DEV=0`, while a value that already is a PCM name (`dsnoop:CARD=Audio,DEV=0`, `default`, `null`, `pulse`, `pipewire`, ...) is used as provided
- Fix: writing `REC_CARD` no longer detaches `birdnet.conf` from `/config`. `sed -i` replaced the `$HOME/BirdNET-Pi/birdnet.conf` symlink with a regular file, so later edits from the WebUI went to a different file than the one the add-on had written; it now edits `/config/birdnet.conf` with `--follow-symlinks`

## 2026.07.10-2 (10-07-2026)
- Minor bugs fixed
## 2026.07.10 (10-07-2026)
- Initial release: BirdNET-Pi add-on based on the zach7036/BirdNET-Pi-Enhanced-Version fork
