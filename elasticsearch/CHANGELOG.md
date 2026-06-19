## 8.14.3-3 (2026-06-19)
- Fix startup failing with `chroot: cannot change root directory` by allowing `capability sys_chroot` in the AppArmor profile (#2709)
- Fix AppArmor profile name (was `inadyn_addon`, colliding with several other add-ons); renamed to `elasticsearch_addon`

## 8.14.3-2 (2025-11-18)
- 8.14.3-1 (2025-11-18)
  - Added `env_vars` option to support custom environment variables from the add-on configuration.

- BREAKING CHANGE : upgrade to v8.14.3. You'll need to rebuild your indexes

## v7
- Implemented healthcheck
- WARNING : update to supervisor 2022.11 before installing
- Add codenotary sign
- New standardized logic for Dockerfile build and packages installation
- Initial build
