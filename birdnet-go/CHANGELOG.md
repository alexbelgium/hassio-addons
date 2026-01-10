
## nightly-20260110 (2026-01-10)
- Update to latest version from tphakala/birdnet-go (changelog : https://github.com/tphakala/birdnet-go/releases)
## nightly-20251223-2 (27-12-2025)
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
