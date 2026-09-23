## 1.3.0.7 (23-09-2026)

- Rebuilt against the current upstream `benkl/firefly-iii-fints-importer`
  image, which ships a php-fints revision where the malformed
  `use Fhp\lib\Fhp\Segment\IPZ\ParameterSEPAInstantPaymentZahlungV2` import
  has been corrected. That import named a class that does not exist, so the
  importer died with a fatal `ReflectionException` as soon as a bank sent an
  `HIIPZS` (SEPA Instant Payment) segment in its BPD response — which DKB
  now does (#3083).
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 1.3.0-6 (2025-10-18)
- Minor bugs fixed
## 1.3.0-5 (2025-10-06)
- Minor bugs fixed

## 1.3.0 (2023-11-05)

- Adds working cron job
- Adds more daily update options differing in the hour of the day at which is updated

## 1.2-11 (2023-09-23)

- Minor bugs fixed
- Implemented healthcheck
- WARNING : update to supervisor 2022.11 before installing
- Add codenotary sign
- Initial release
- Removes image reference from config.yaml so build config is used
