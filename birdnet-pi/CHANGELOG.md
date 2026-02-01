## 2026.02.01 (01-02-2026)
- Minor bugs fixed
## 2026.01.21 (21-01-2026)
- Fix passwordless terminal

## 2025.12-05 (2025-12-20)
- Minor bugs fixed
## 2025.12-04 (2025-12-19)
- Minor bugs fixed
## 2025.12.03 (2025-12-19)
- Minor bugs fixed
## 2025.12.01 (2025-12-19)
- Minor bugs fixed

## 0.11 (2025-11-29)
- Update to latest version from Nachtzuster/BirdNET-Pi (changelog : https://github.com/Nachtzuster/BirdNET-Pi/releases)
## 2025.11.09 (2025-11-20)
- Minor bugs fixed
## 2025.11.07 (2025-11-16)
- Minor bugs fixed
## 2025.11.06 (2025-11-15)
- Minor bugs fixed
## 2025.11.05 (2025-11-15)
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 2025.11.04 (2025-11-05)
- Minor bugs fixed
## 2025.11.03 (2025-11-04)
- Minor bugs fixed
## 2025.11.02 (2025-11-01)
- Minor bugs fixed
## 2025.10.02 (2025-10-07)
- Minor bugs fixed
## 2025.10.01 (2025-10-05)
- Remove updates indicator

## 2025.09.12 (2025-09-20)
- Minor bugs fixed
## 2025.09.11 (2025-09-14)
- New option to use tphakala's modified model

## 2025.09.04 (2025-09-12)
- Minor bugs fixed
## 2025.09.03 (2025-09-09)
- Minor bugs fixed

## 2025.09.01 (2025-09-07)
- Improve pulseaudio start when running container standalone
## 2025.08.23 (2025-08-25)
- Minor bugs fixed
## 2025.08.22 (2025-08-24)
- Fix interactive graph
- Fix weekly report

## 2025.08.16 (2025-08-20)
- Cleaned code and clarify new options
  - Add interactive chart option : #107
  - New plot : #105
  - Add species management tools : #104
  - Add species confirmation option to recordings : #102
  - Add selectable duration mini-graphs for species pages : #101

## 2025.08.15 (2025-08-20)
- Minor bugs fixed
## 2025.08.14 (2025-08-19)
- Minor bugs fixed
## 2025.08.13 (2025-08-19)
- Minor bugs fixed
## 2025.08.12 (2025-08-17)
- Minor bugs fixed
## 2025.08.11 (2025-08-11)
- Fix audio group to detect USB sound cards

## 2025.08.10 (2025-08-10)
- Fix web terminal password when running container standalone

## 2025.07.09 (2025-08-04)
- Minor bugs fixed
## 2025.07.08 (2025-08-04)
- Minor bugs fixed
## 2025.07.07 (2025-08-04)
- Fix pulseaudio standalone @ignmedia

## 2025.07.06 (2025-08-03)
- Use wikipedia for images

## 2025.07.01 (2025-07-24)
- Fix birdweather

## 2025.04.08 (2025-04-29)
- Minor bugs fixed
## 2025.04.07 (2025-04-28)
- Minor bugs fixed
## 2025.04.06 (2025-04-28)
- Minor bugs fixed
## 2025.04.05 (2025-04-28)
- Minor bugs fixed
## 2025.04.04 (2025-04-19)
- Minor bugs fixed
## 2025.04.03 (2025-04-16)
- Minor bugs fixed
## 2025.04.02 (2025-04-14)
- Minor bugs fixed
## 2025.04.01 (2025-04-06)
- Align to upstream
- Fix timezone https://github.com/alexbelgium/hassio-addons/issues/1664

## 2025.03.29 (2025-03-28)
- [DOCKER] Use ALSA_CARD to define card to use ; or else use REC_CARD in birdnet.conf

## 2025.03.25 (2025-03-27)
- [DOCKER] Enable pulseaudio if HA is not used

## 2025.03.22 (2025-03-13)
- [ALL] Use Nachtzuster universal tflite 2.17.1 runtimes allowing full compatibility with non avx cpu

## 2025.03.19 (2025-03-08)
- [ALL] Default Flickr API key if not provided
- [Non-avx2] Use tflite built with non-avx2 instructions

## 2025.03.18 (2025-03-06)
- [ALL] Upgrade tflite from 2.11 to 2.17.1
- [ALL] Use tensorflow 1.5 if non-avx2 detected
- [DOCKER] Improved restart mode

## 2025.03.10 (2025-03-04)
- [ALL] Fix stats bug
- [ADDON] Fix clicking on links on dynamic graph
- [ADDON] Allow statistics in ingress

## 2025.03.04 (2025-03-03)
- [DOCKER] Allow files recovery on restart

## 2025.03.03 (2025-03-02)
- [DOCKER] Allow standalone restart
- [ALL] Fix non-avx2 cpu support

## 2025.02.23 (2025-02-16)
- WARNING 2025.02.14/16 was buggy. If you installed it you need to restore a backup or delete manually your /addon_configs/xxx-birdnet-pi/birdnet.conf file and recreate it
- Allow usage as a standalone container (thanks @gotschi) https://github.com/mcguirepr89/BirdNET-Pi/issues/211#issuecomment-2650095952
- Corrected a bug preventing to create db
- Corrected a bug to ensure the the most up-to-date birdnet.conf on fresh start
- Fixed daily plot not initializing on empty database

## 2025.02.02 (2025-02-07)
- Fix audio not playing in microsoft edge

## 2025.02.01 (2025-02-05)
- Improved monitoring system
- Improved audio player (clear browser cache)

## 2025.01-11 (2025-01-28)
- New audio player
- Upgraded upstream code : various improvements

## 2025.01-7 (2025-01-09)
- Fix mqtt autodetect script

## 2025.01-4 (2025-01-08)
- Older CPU support : install tensorflow if avx2 not available
- Align to upstream

## 0.13-106 (2024-10-30)
- Implement interactive plot

## 0.13-103 (2024-10-30)
- Fix : recording service always restarting

## 0.13-102 (2024-10-29)
- Improve logging

## 0.13-101 (2024-10-29)
- Update upstream

## 0.13-98 (2024-10-07)
- [SERVER] Fix timezone not correctly shown in config options

## 0.13-97 (2024-10-05)
- [SERVER] Fix timezone. Use by priority : TZ defined in addon options, TZ defined in BirdNET-options, or automatic TZ
- [UI] New species are highlighted on top of overview page

## 0.13-95 (2024-10-02)
- [UI/Feat] Add toggle switches for purge and confirmed species

## 0.13-90 (2024-09-25)
- [UI] Sort species by max detections
- [UI] Consistent layout between overview and todays pages
- [SERVER] Add error messages for species not detected

## 0.13-88 (2024-09-14)
- Define cache folder for matplotlib
- Fix confirmed species
- Update to latest

## 0.13-86 (2024-08-16)
- [MQTT] Fix auto detection @UlrichThiess

## 0.13-83 (2024-08-14)
- [MQTT] Change logic as a hook in birdnet_analysis instead of a service
- [DEFAULT] disable by default autopublishing of MQTT

## 0.13-79 (2024-08-13)
- [MQTT] : add Flickrimage to mqtt tags when a flickr API is defined in options

## 0.13-75 (2024-08-08)
- Fix : improve symlinks logic

## 0.13-73 (2024-08-07)
- [REMOVE] : SPECIES_CONVERTER_ENABLED option removed, please instead us "exclude species" and "change detection"
- [FEAT] : Improve dark mode
- [FEAT] : Species confirmation

## 0.13-71 (2024-07-14)
- [FEAT] : Add manual MQTT options

## 0.13-69 (2024-07-12)
- [FEAT] : limit a specific number of audio samples per species

## 0.13-68 (2024-07-10)
- [FIX] : correct mqtt posting, switch to service

## 0.13-65 (2024-07-08)
- [FEAT] : publish mqtt to homeassistant if a server is found

## 0.13-61 (2024-06-30)
- [FIX] : safeguard to avoid embedded pulseaudio interference

## 0.13-58 (2024-06-27)
- [UI] : Improved dark mode
- [UI] : New standardized behavior of click on Com_Name and Sci_Name
- [FEAT] : add species whitelist
- [FEAT] : new disk usage settings

## 0.13-55 (2024-06-19)
- Several upstream improvements
- Disable by default livrestream on boot : reduce idle cpu by half
- Remove 24bits analysis, did not provide any benefits

## 0.13-54 (2024-06-15)
- Several upstream improvements
- Feat : analysis in 24bits with ANALYSIS_24BITS. The model is however trained in 16bits. Increases resources, and to use only if you have a 24 bits stream

## 0.13-52 (2024-06-10)
- Fix : improve timedatectl management in options

## 0.13-51 (2024-06-08)
- Update to latest upstream
- Fix : time setting in options (don't forget that the timezone is set from addon options)
- New addon option : LIVESTREAM_BOOT_ENABLED enables livestream from boot. Disable to save resources

## 0.13-50 (2024-06-04)
- Minor bugs fixed

## 0.13-49 (2024-06-03)
- New option "Color_scheme" : add darkmode option from the options tag (might require you to manually add the COLOR_SCHEME to your birdnet.conf)
- New option "Processed_Buffer" : defines the number of last wav files that will be saved in the temporary folder "/tmp/Processed" within the tmpfs (so no disk wear) in case you want to retrieve them. This amount can be adapted from the addon options
- Species converter is again optional to avoid messing with the main analyzer except if required

## 0.13-48 (2024-05-30)
- eBird selection feature is now moved to the BirdNET-Pi settings (thanks @nachtzuster)

## 0.13-47 (2024-05-30)
- Add weekly report button to views
- Use optional iframe for Adminer
- Enable species converter by default (only active if used)

## 0.13-46 (2024-05-23)
- Security : enable double layer basic auth with caddy in addition to php when connecting without ingress
- Update to latest Birdnet-pi
- [SSL] : allow usage of caddy's automated ssl by mapping 80 to port 80 in the addons option, and defining an https address in the birdnet.conf
- [SSL] : allow usage of HomeAssistant's let's encrypt certificates by enabling ssl from the addon options. No need to specify the website address in birdnet.conf but the certificate described must match the address used to access birdnet.pi

## 0.13-37 (2024-05-20)
- BREAKING CHANGE : the main port has changed from 80 to 8081 to allow ssl
- [INGRESS] allow access to streamlit, logs

## 0.13-33 (2024-05-19)
- [INGRESS] Allow access to restricted area without password if authentificated from within the homeassistant app
- [SPECIES_CONVERTER] : fixed

## 0.13-31 (2024-05-19)
- [SPECIES_CONVERTER] : Significantly improve, add a webui when the option is enabled
- [SPECIES_CONVERTER] : Improve the SPECIES_CONVERTER webui with input text filtering in both browser and mobile

## 0.13-28 (2024-05-17)
- [SPECIES_CONVERTER] : New option ; if enabled, you need to put in the file /config/convert_species_list.txt the list of species you want to convert (example : Falco subbuteo_Faucon hobereau;Falco tinnunculus_Faucon Crécerelle). It will convert on the fly the specie when detected. This is not enabled by default as can be a cause for issues
- Improve code clarity by separating modifications of code to make it work, and new features specific to the addon

## 0.13-27 (2024-05-15)
- [CHANGE DETECTION] : Enable new feature to change detection from webui

## 0.13-25 (2024-05-13)
- Allow ssl using certificates generated by let's encrypt

## 0.13-24 (2024-05-12)
- Enable cron jobs

## 0.13-23 (2024-05-11)
- Improve throttle service
- Improve data recovery upon analyser stop

## 0.13-20 (2024-05-02)
- Minor bugs fixed

## 0.13-19 (2024-05-02)
- Fix : show container logs in "View log"
- Feat : new command line script to change the identification of a bird (changes database & files location)
- Fix : correct chmod defaults

## 0.13-17 (2024-05-01)
- Feat : Send service logs to docker container
- Feat : re-add the throttle service
- Feat : ensure no data from tpmfs is lost when the container is closed by saving it to a temporary place, and restoring on restart

## 0.13-11 (2024-05-01)
- Feat : use pi_password to define the user password from the addon options

## 0.13-8 (2024-04-29)
- Improve ingress
- Fix : give caddy UID 1000 to allow deletion of files owned by pi

## 0.13-5 (2024-04-29)
- Feat : addon option to use allaboutbird (US) or ebird (international) for additional birds info
- Remove throttle script due to interactions with analysis service

## 0.13 (2024-04-28)
- Fix : ensure correct labels language is used at boot
- Feat : add throttle recording service from @JohnButcher https://github.com/mcguirepr89/BirdNET-Pi/issues/393#issuecomment-1166445710
- Feat : use tmpfs from StreamData to reduce disk wear
- Feat : definition of BirdSongs folder through an addon option, existing data will not be migrated
- Add support for /config/include_species_list.txt and /config/exclude_species_list.txt
- Add support for apprise, txt, clean code
- Initial build
