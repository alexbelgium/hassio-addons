- Improved monitoring system
- Improved audio player (clear browser cache)

## 2025.01-11 (28-01-2025)
- New audio player
- Upgraded upstream code : various improvements

## 2025.01-7 (09-01-2025)
- Fix mqtt autodetect script

## 2025.01-4 (08-01-2025)
- Older CPU support : install tensorflow if avx2 not available
- Align to upstream

## 0.13-106 (30-10-2024)
- Implement interactive plot

## 0.13-103 (30-10-2024)
- Fix : recording service always restarting

## 0.13-102 (29-10-2024)
- Improve logging

## 0.13-101 (29-10-2024)
- Update upstream

## 0.13-98 (07-10-2024)
- [SERVER] Fix timezone not correctly shown in config options

## 0.13-97 (05-10-2024)
- [SERVER] Fix timezone. Use by priority : TZ defined in addon options, TZ defined in BirdNET-options, or automatic TZ
- [UI] New species are highlighted on top of overview page

## 0.13-95 (02-10-2024)
- [UI/Feat] Add toggle switches for purge and confirmed species

## 0.13-90 (25-09-2024)
- [UI] Sort species by max detections
- [UI] Consistent layout between overview and todays pages
- [SERVER] Add error messages for species not detected

## 0.13-88 (14-09-2024)
- Define cache folder for matplotlib
- Fix confirmed species
- Update to latest

## 0.13-86 (16-08-2024)
- [MQTT] Fix auto detection @UlrichThiess

## 0.13-83 (14-08-2024)
- [MQTT] Change logic as a hook in birdnet_analysis instead of a service
- [DEFAULT] disable by default autopublishing of MQTT

## 0.13-79 (13-08-2024)
- [MQTT] : add Flickrimage to mqtt tags when a flickr API is defined in options

## 0.13-75 (08-08-2024)
- Fix : improve symlinks logic

## 0.13-73 (07-08-2024)
- [REMOVE] : SPECIES_CONVERTER_ENABLED option removed, please instead us "exclude species" and "change detection"
- [FEAT] : Improve dark mode
- [FEAT] : Species confirmation

## 0.13-71 (14-07-2024)
- [FEAT] : Add manual MQTT options

## 0.13-69 (12-07-2024)
- [FEAT] : limit a specific number of audio samples per species

## 0.13-68 (10-07-2024)
- [FIX] : correct mqtt posting, switch to service

## 0.13-65 (08-07-2024)
- [FEAT] : publish mqtt to homeassistant if a server is found

## 0.13-61 (30-06-2024)
- [FIX] : safeguard to avoid embedded pulseaudio interference

## 0.13-58 (27-06-2024)
- [UI] : Improved dark mode
- [UI] : New standardized behavior of click on Com_Name and Sci_Name
- [FEAT] : add species whitelist
- [FEAT] : new disk usage settings

## 0.13-55 (19-06-2024)
- Several upstream improvements
- Disable by default livrestream on boot : reduce idle cpu by half
- Remove 24bits analysis, did not provide any benefits

## 0.13-54 (15-06-2024)
- Several upstream improvements
- Feat : analysis in 24bits with ANALYSIS_24BITS. The model is however trained in 16bits. Increases resources, and to use only if you have a 24 bits stream

## 0.13-52 (10-06-2024)
- Fix : improve timedatectl management in options

## 0.13-51 (08-06-2024)
- Update to latest upstream
- Fix : time setting in options (don't forget that the timezone is set from addon options)
- New addon option : LIVESTREAM_BOOT_ENABLED enables livestream from boot. Disable to save resources

## 0.13-50 (04-06-2024)
- Minor bugs fixed

## 0.13-49 (03-06-2024)
- New option "Color_scheme" : add darkmode option from the options tag (might require you to manually add the COLOR_SCHEME to your birdnet.conf)
- New option "Processed_Buffer" : defines the number of last wav files that will be saved in the temporary folder "/tmp/Processed" within the tmpfs (so no disk wear) in case you want to retrieve them. This amount can be adapted from the addon options
- Species converter is again optional to avoid messing with the main analyzer except if required

## 0.13-48 (30-05-2024)
- eBird selection feature is now moved to the BirdNET-Pi settings (thanks @nachtzuster)

## 0.13-47 (30-05-2024)
- Add weekly report button to views
- Use optional iframe for Adminer
- Enable species converter by default (only active if used)

## 0.13-46 (23-05-2024)
- Security : enable double layer basic auth with caddy in addition to php when connecting without ingress
- Update to latest Birdnet-pi
- [SSL] : allow usage of caddy's automated ssl by mapping 80 to port 80 in the addons option, and defining an https address in the birdnet.conf
- [SSL] : allow usage of HomeAssistant's let's encrypt certificates by enabling ssl from the addon options. No need to specify the website address in birdnet.conf but the certificate described must match the address used to access birdnet.pi

## 0.13-37 (20-05-2024)
- BREAKING CHANGE : the main port has changed from 80 to 8081 to allow ssl
- [INGRESS] allow access to streamlit, logs

## 0.13-33 (19-05-2024)
- [INGRESS] Allow access to restricted area without password if authentificated from within the homeassistant app
- [SPECIES_CONVERTER] : fixed

## 0.13-31 (19-05-2024)
- [SPECIES_CONVERTER] : Significantly improve, add a webui when the option is enabled
- [SPECIES_CONVERTER] : Improve the SPECIES_CONVERTER webui with input text filtering in both browser and mobile

## 0.13-28 (17-05-2024)
- [SPECIES_CONVERTER] : New option ; if enabled, you need to put in the file /config/convert_species_list.txt the list of species you want to convert (example : Falco subbuteo_Faucon hobereau;Falco tinnunculus_Faucon Crécerelle). It will convert on the fly the specie when detected. This is not enabled by default as can be a cause for issues
- Improve code clarity by separating modifications of code to make it work, and new features specific to the addon

## 0.13-27 (15-05-2024)
- [CHANGE DETECTION] : Enable new feature to change detection from webui

## 0.13-25 (13-05-2024)
- Allow ssl using certificates generated by let's encrypt

## 0.13-24 (12-05-2024)
- Enable cron jobs

## 0.13-23 (11-05-2024)
- Improve throttle service
- Improve data recovery upon analyser stop

## 0.13-20 (02-05-2024)
- Minor bugs fixed

## 0.13-19 (02-05-2024)
- Fix : show container logs in "View log"
- Feat : new command line script to change the identification of a bird (changes database & files location)
- Fix : correct chmod defaults

## 0.13-17 (01-05-2024)
- Feat : Send service logs to docker container
- Feat : re-add the throttle service
- Feat : ensure no data from tpmfs is lost when the container is closed by saving it to a temporary place, and restoring on restart

## 0.13-11 (01-05-2024)
- Feat : use pi_password to define the user password from the addon options

## 0.13-8 (29-04-2024)
- Improve ingress
- Fix : give caddy UID 1000 to allow deletion of files owned by pi

## 0.13-5 (29-04-2024)
- Feat : addon option to use allaboutbird (US) or ebird (international) for additional birds info
- Remove throttle script due to interactions with analysis service

## 0.13 (28-04-2024)
- Fix : ensure correct labels language is used at boot
- Feat : add throttle recording service from @JohnButcher https://github.com/mcguirepr89/BirdNET-Pi/issues/393#issuecomment-1166445710
- Feat : use tmpfs from StreamData to reduce disk wear
- Feat : definition of BirdSongs folder through an addon option, existing data will not be migrated
- Add support for /config/include_species_list.txt and /config/exclude_species_list.txt
- Add support for apprise, txt, clean code
- Initial build
