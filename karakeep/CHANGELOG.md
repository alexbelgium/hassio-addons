# 0.30.0 (New year release 🎁)

Welcome to the 0.30.0 release of Karakeep and happy new year! This release comes with "2025 wrapped" (a bit late), PDF archives, new reader settings, avatars, reddit crawling improvements, and more! Huge thanks to our contributors for this release @esimkowitz, @Moondragon85, @rzxczxc, @colado, @Yeraze, @eriktews and everyone who shipped code, triaged bugs, or shared feedback for this release.

> If you enjoy using Karakeep, consider supporting the project [here ☕️](https://buymeacoffee.com/mbassem) or via GitHub [here](https://github.com/sponsors/MohamedBassem).

<a href="https://www.buymeacoffee.com/mbassem" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="auto" height="50" ></a>

And in case you missed it, we now have a ☁️ managed offering ☁️ for those who don't want to self-host. We're in public beta now and you can signup [here](https://cloud.karakeep.app) 🎉.

# New Features 🚀

- 2025 Wrapped is here to celebrate your year in Karakeep (#2322).
- PDF archives
  - Archive bookmarks as PDFs, generated automatically during crawling or on-demand (#2309).
  - Set `CRAWLER_STORE_PDF=true` to enable auto PDF archiving.
- Unified reader settings (font, size, etc) across all devices with per-device overrides (#2230). By @esimkowitz!
- Better metadata extraction:
  - Reddit posts should now be crawled correctly, and banners should be fetched more reliably.
  - Fixed YouTube thumbnail and author extraction.
  - Fixed Amazon product image extraction (where it was sometimes showing the prime logo) (#2204, #2108). By @Yeraze
- Upload custom user avatars for more personal profiles (#2296).
- AI Setting customization:
  - Customize tag styling (case, separators, language) per user. It's highly recommended to set the tag style for more consistent tags (#2312).
  - Per-user toggles to disable auto-tagging and/or auto-summarization (#2275).
- Others:
  - Import libraries from Matter with full export support (#2245). By @Moondragon85
  - Bulk remove bookmarks from lists (#2279).
  - Add a new rule condition to rule engine: "URL Does Not Contain" (#2280).
  - Configure an OpenAI proxy via `OPENAI_PROXY_URL` (#2231). By @rzxczxc
  - Added `is:broken` search qualifier to show links that failed crawling (#2225).
  - Edit list now in the mobile app (#2310). By @colado 

# UX Improvements ✨

- Our docs got a facelift! The docs got some styling, the pages got re-organized and we now have a "Using Karakeep" section that explains some of the core concepts of Karakeep.
- Replace bookmark banners and download attachments directly from the drop down menu (#2328).
- Sidebar scrollbar looks cleaner, and pending list invites show as a badge in the sidebar.
- Bookmark edit dialog now includes notes.
- Bookmark owner avatars now show up in collaborative lists.
- Mobile UI/UX improvements:
  - Fixed title on mobile to be at most 2 lines long.
  - Mobile settings screens should now feel more native (#2307).
  - OLED-friendly colors in the Android app matching the colors of the ios app (#1958).
  - Toasts on iOS now appear correctly above the open modals (#2320). By @colado
  - Shared lists now appear in a dedicated subsection on mobile.
  - Adding a bookmark to a list now shows a spinner during loading (#2283).
  - Server version now appears in mobile settings (#2276).
  - Fixed the confusing "tick button" beside the server address during login.

# Fixes 🔧

- Fixed missing db indicies that was causing slow bookmark queries (#2246, #2287).
- Improved Ollama summaries by using the generate endpoint (#2324). By @eriktews
- Fixed HTML bookmark imports failing on empty folder names (#2300).
- Fixed non-link bookmarks stuck in pending summarization (#1605).
- Improved tagging prompts and error-page detection.
- Reject spoofed content types on file uploads.
- Preserve failure counts when rescheduling rate-limited domains (#2303).
- Fixed duplicate backdrop buttons in reader view (#2234). By @colado
- RSS feed fetching is now spread over the hour (#2227).
- Asset preprocessing worker timeout is now configurable (91784cd2).
- Fixed bypassing email verification in apiKey.exchange.
- Added limits on number of rss feeds and webhooks per user configurable by admins.
- Fixed a bug where failed crawling leave bookmarks as pending tagging in the admin dashboard.

# For Developers 🛠️

- OpenTelemetry integration with OTLP exporter (#2318, #2321).
- CLI can list users for admins.
- We're now defaulting to Node.js 24 (the current LTS).
- Breaking: In bookmark APIs `includeContent` now defaults to `false`. This change was announced a couple months ago, and is taking effect in this release.

# Community Projects 💡

- Karakeep integration for Home Assistant (#2196) by @sli-cka. Get it from [here](https://github.com/sli-cka/karakeep-homeassistant).

# Screenshots 📸

## Wrapped 2025

![karakeep-wrapped-2025](https://github.com/user-attachments/assets/0e1e3d25-c827-4974-8f0a-9b7b4a75f859)

## Reader Settings

![https://github.com/user-attachments/assets/4d81cb80-f9b8-43f2-998a-736f18e33038](https://github.com/user-attachments/assets/4d81cb80-f9b8-43f2-998a-736f18e33038).


### AI Settings

![https://github.com/user-attachments/assets/48032bf6-5413-44ee-9c3b-ac7b385aeccf](https://github.com/user-attachments/assets/48032bf6-5413-44ee-9c3b-ac7b385aeccf)



# Upgrading 📦

To upgrade:
* If you're using `KARAKEEP_VERSION=release`, run `docker compose pull && docker compose up -d`.
* If you're pinning it to a specific version, bump the version and then run `docker compose pull && docker compose up -d`.

# All Commits

* i18n: fix en_US translation - @MohamedBassem in d472a3a1
* fix: fix wrapped feature to only show bookmarks in 2025 - @MohamedBassem in 4077e286
* i18n: Sync weblate translations - Weblate in 401ea6a9
* chore: drop the experimental tag from the rule engine - @MohamedBassem in bf9d6105
* fix: show a toast during banner upload - @MohamedBassem in 9555f409
* fix: don't switch the bookmark back to pending on recrawl - @MohamedBassem in 79400d04
* fix: use the Ollama generate endpoint instead of chat (#2324) - @eriktews in e8c79f29
* feat: add replace banner and attachment download (#2328) - @MohamedBassem in 3d652eee
* feat: Add bulk remove from list (#2279) - @MohamedBassem in 7a76216e
* feat: add "URL Does Not Contain" condition to rule engine (#2280) - @MohamedBassem in b20ba9cf
* feat: 2025 wrapped (#2322) - @MohamedBassem in a0b4a26a
* chore: worker tracing (#2321) - @MohamedBassem in 7ab7db8e
* feat(landing): add corporate pricing - @MohamedBassem in d852ee1a
* fix(mobile): mobile modal UI issues (#2320) - @colado in a43d375f
* ci: fix tests - @MohamedBassem in 9d6b1282
* feat: change default for tag style to be title case with spaces - @MohamedBassem in 9098a5a6
* fix: more tagging tweaks - @MohamedBassem in c1cbaa8a
* build: fix broken CI - @MohamedBassem in a5ce977d
* fix: change prompt to better recognize error pages - @MohamedBassem in f5a5c14e
* refactor: reduce duplication in compare-models tool - @MohamedBassem in f00287ed
* chore: add tracing for email functions - @MohamedBassem in ba8d84a5
* feat(mobile): create new list edit screen (#2310) - @colado in 30fa06fe
* feat: Add open telemetry (#2318) - @MohamedBassem in 5537fe85
*  fix: reset tagging status on crawl failure  (#2316) - @MohamedBassem in f7920bdc
* feat: add the ability to specify a different changelog version - @MohamedBassem in 10820761
* fix: remove duplicate mobile backdrop button in reader view (#2234) - @esimkowitz in 3f44e319
* fix(landing): fix cloud banner on mobile - @MohamedBassem in 23f28530
* refactor: add suspense boundary in sidebar layout - @MohamedBassem in 3c3d8685
* feat(mobile): make the settings menu look more native (#2307) - @MohamedBassem in 6ee48ffb
* feat(web): better looking scrollbar in the sidebar - @MohamedBassem in f7523a21
* feat(mobile): use oled friendly colors for android app. fixes #1958 - @MohamedBassem in e800d744
* refactor: migrate toasts to sonner - @MohamedBassem in 173fb99a
* feat: add customizable tag styles (#2312) - @MohamedBassem in af3010ab
* feat: add Matter import support (#2245) - @Moondragon85 in 93630ce8
* feat: support archiving as pdf (#2309) - @MohamedBassem in 267db791
* feat: add OPENAI_PROXY_URL configuration and support for proxy in OpenAI client (#2231) - @rzxczxc in bb6b742a
* fix(tests): fix the asset upload tests - @MohamedBassem in e82694de
* fix: reject spoofed content types on uploads - @MohamedBassem in 2dbdf76c
* deps: upgrade tesseract to v7 - @MohamedBassem in 347793ad
* feat(landing): announce cloud public beta in landing page - @MohamedBassem in c3b2326c
* chore: add a tool for comparing perf of different models - @MohamedBassem in 1dfa5d12
* feat: add notes to the bookmark edit dialog - @MohamedBassem in ecb7a710
* fix(restate): change journal retention for services to 3d - @MohamedBassem in 0efffdcc
* fix(cli): migrate bookmark source in migration command - @MohamedBassem in 65cfa871
* fix: preserve failure count when rescheduling rate limited domains (#2303) - @MohamedBassem in ddd4b578
* feat: show bookmark owner icon in shared lists (#2277) - @MohamedBassem in ef27670f
* fix: make avatars public - @MohamedBassem in f7d34627
* refactor: move assets to their own model (#2301) - @MohamedBassem in 013ca67c
* feat: add support for user avatars (#2296) - @MohamedBassem in 314c363e
* fix: handle empty folder names in HTML bookmark imports (#2300) - @MohamedBassem in 3408e6e4
* feat: add a warning about viewing archives inline. fixes #2286 - @MohamedBassem in e336513f
* fix(tests): fix the user setting tests - @MohamedBassem in 258bebe0
* feat: Add user settings to disable auto tagging/summarization (#2275) - @MohamedBassem in 0bdba54b
* feat(mobile): Convert server address editing to modal in mobile app (#2290) - @MohamedBassem in ece68ed0
* fix: check quota usage instead bookmark transaction - @MohamedBassem in ca4bfa4c
* fix: optimize tagging db queries (#2287) - @MohamedBassem in e18dc4c9
* docs: shuffle some docs around - @MohamedBassem in 4762da12
* docs: add RSS feeds integration documentation (#2288) - @MohamedBassem in 903aa5e9
* feat(restate): Add a var to control whether to expose core services or not - @MohamedBassem in dc8ab862
* feat: add more restate semaphore controls - @MohamedBassem in 58eb6c00
* feat(mobile): Show shared lists under a subsection - @MohamedBassem in 837dea5e
* fix(mobile): Fix title line clamp to 2 lines - @MohamedBassem in 15cfa137
* fix(mobile): Add loading spinner to mobile list button (#2283) - @MohamedBassem in 7b98c52a
* feat: add server version display to mobile app settings (#2276) - @MohamedBassem in bd969b34
* fix: add authentication checks to settings layout (#2274) - @MohamedBassem in e53f3ae5
* fix: only trigger search autocomplete on first search char - @MohamedBassem in 92e352f3
* feat(landing): remove waitlist link. fixes #2270 - @MohamedBassem in e842c5a7
* fix: don't fail the script if the user karakeep already exists. fixes #2242 - @MohamedBassem in e78e5129
* fix: collapse reader settings by default - @MohamedBassem in 3955f91a
* docs: Add icons beside category names - @MohamedBassem in 9021822a
* Revert "fix: fix restate service to return control to restate service on timeout" - @MohamedBassem in 510174db
* feat: Add unified reader settings with local overrides (#2230) - @esimkowitz in 7f4202af
* fix: fix restate service to return control to restate service on timeout - @MohamedBassem in 6db14ac4
* fix: non-link bookmarks where stuck in pending summarization. Fixes #1605 - @MohamedBassem in d7357118
* fix: move trpc error logging inside the dev check - @MohamedBassem in 0b65e5a4
* fix: Fix Amazon product image extraction on amazon.com URLs (#2108) - @Yeraze in b3196354
* feat: use reddit API for metadata extraction. Fixes #1853 #1883 - @MohamedBassem in f5c32d94
* fix: use GET requests for the content type request - @MohamedBassem in d6dd8ebd
* docs: fix sidebar on mobile - @MohamedBassem in f111cba9
* feat: Add limits on number of rss feeds and webhooks per user - @MohamedBassem in 74df8bd7
* release(cli): Bump CLI version to 0.29.1 - @MohamedBassem in 697c853a
* readme: some readme updates - @MohamedBassem in 1ebc721c
* docs: Update screenshots in docs - @MohamedBassem in c6cf4188
* docs: Adding user guides - @MohamedBassem in 04b9c291
* docs: drop docs for old versions - @MohamedBassem in fecb0079
* docs: restructure the docs - @MohamedBassem in af69f637
* docs: restyle the docs - @MohamedBassem in b4344401
* ci: run CI with node 24 - @MohamedBassem in 2bdba536
* deps: Upgrade to nodejs 24 - @MohamedBassem in 480abce4
* fix!: changing default for includeContent to be false in the API - @MohamedBassem in 1369ad01
* deps: Upgrade nextjs to 15.3.8 - @MohamedBassem in 80278ecf
* deps: Upgrade nextjs to 15.3.7 - @MohamedBassem in 74bdc186
* fix: add more indicies for faster bookmark queries (#2246) - @MohamedBassem in 683083f4
* feat: make asset preprocessing worker timeout configurable - @Claude in 91784cd2
* fix: Add cache control header on asset endpoints - @MohamedBassem in 3e8cc745
* chore: Allowing multi user benchmarks and adding more coverage - @MohamedBassem in 265b6773
* feat(cli): Add ability to list users for the admin in the CLI - @MohamedBassem in 69a756aa
* fix: fix correctly accounting for text bookmark in import sessions. #2208 - @MohamedBassem in 6886385c
* fix: check import quota before importing bookmarks (#2232) - @MohamedBassem in 20d3761c
* build: fix typecheck error in query explainer - @MohamedBassem in b6c2dadd
* fix: migrate to metascraper-x from metascraper-twitter - @MohamedBassem in c6f93b3b
* feat: add is:broken search qualifier for broken links (#2225) - @MohamedBassem in 1f43f232
* feat: spread feed fetch scheduling deterministically over the hour (#2227) - @MohamedBassem in 13a090c4
* fix: better extraction for youtube thumbnails. #2204 - @MohamedBassem in e3cc5463
* fix: remove queue triggers outside of updateTags transaction - @MohamedBassem in cf2a12c8
* chore: add benchmarks (#2229) - @MohamedBassem in 6180c662
* build: dont update latest tags on release - @MohamedBassem in de98873a
* deps: Upgrade nextjs to 15.3.6 - @MohamedBassem in 20081a3a
* feat: add a notification badge for list invitations - @MohamedBassem in 3c6b8e97
* docs: add karakeep integration for Home Assistant (#2196) - @sli-cka in 9a339385
* fix: regen turnstile token on signup resubmission - @MohamedBassem in 9257b534
* feat(landing): Add more features to the homepage - @MohamedBassem in 9a6d36f2
* ci: run arm docker image builds on arm machines - @MohamedBassem in 3421246d
* ci: parallelize the docker workflow for platforms - @MohamedBassem in 2e889617
* fix: reenable idempotency key for search indexing - @MohamedBassem in 2ef751ef
* fix: fix bypass email verification in apiKey.exchange - @MohamedBassem in e4f434e7
* readme: add collaborative lists to the list of features - @MohamedBassem in d6d319d3
* fix: Add restate queued idempotency (#2169) - @MohamedBassem in a71b9505
* feat: add support for turnstile on signup - @MohamedBassem in b12c1c3a
* build: fix npm trusted publishing - @MohamedBassem in 4898b6be
* release: cli, mcp and sdk - @MohamedBassem in 28d6750e
* release(extension): Release version 1.2.8 - @MohamedBassem in fdea0861
* release(mobile): Bump mobile version to 1.8.3 - @MohamedBassem in 8da5b598
* release(docs): release the 0.29 docs - @MohamedBassem in 97c386a4
