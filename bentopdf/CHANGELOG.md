## 2.8.8 (03-09-2026)

- Now builds upstream's Simple Mode release instead of the standard one. It leaves out the bentopdf.com marketing pages (nav bar, hero, features, FAQ, footer). Both builds carry the same 130 tool pages and the same LibreOffice WebAssembly payload, so the served payload just gets smaller: about 228 MB, down from about 258 MB.
- Breaking: you can no longer reach the marketing UI, and there is no way to bring it back.
- Upstream BentoPDF is now v2.8.8: <https://github.com/alam00000/bentopdf/releases/tag/v2.8.8>
- That includes the v2.8.7 security fixes (GHSA-wh78-rcw2-hhg9, GHSA-5xjf-rr5x-pcfj, GHSA-cx8x-7rrr-r9x8), which cover every version through v2.8.6
- Version mismatch fixed. The image built upstream 2.8.2 while reporting 2.8.4; `ARG BUILD_VERSION` now matches `version`
- Added `updater.json` so `addons_updater` now tracks upstream releases automatically

## 2.8.4 (24-04-2026)

- Minor bugs fixed

## 2.8.2 (07-04-2026)

- Minor bugs fixed

# Changelog

## 2.8.2

- Update to upstream BentoPDF v2.8.2

## 2.5.0

- Initial release of BentoPDF Home Assistant add-on
- Based on upstream BentoPDF v2.5.0
- Serves 50+ client-side PDF tools via nginx on port 8080
- Supports amd64 and aarch64
