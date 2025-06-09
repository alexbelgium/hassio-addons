- Avoid blank config.json when using xonfig.yaml

## 3.19.9

- Automatically add a link to the release tab when using a github repo to facilitate access to upstream changelog

## 3.19

- New HA config logic implemented. Files are now located in the addon config file, that can be accessed from the addon_configs folder from my filebrowser or cloudcommander addons. Migration of data, custom configs, and custom scripts should be automatic. Please be sure to update all your links however ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/
- Feat : if there is no releases in a github repo, check if there is a valid package and get the highest tag https://github.com/alexbelgium/hassio-addons/issues/1168
- Feat : github_exclude applies to dockerhub

## 3.18

- github_exclude: exclude a text in the release name
- Correct github_tagfilter usage in dockerhub

## 3.17

- Clean cache

## 3.16

- Removed git password option as it is no longer usable

## 3.15

- Apply github_tagfilter to dockerhub

## 3.10

- Add dry run mode (test but does not commit)

## 3.9.9

- Add mode
- WARNING : update to supervisor 2022.11 before installing
- Fix : dockerhub_list_size corrected
- New dockerhub_list_size tag for dockerhub
- Look for last 100 elements instead of 10
- New dockerhub_by_date tag for dockerhub
- Nightly tag only for beta
- Use latest lastversion & base images
- Feat: "pause: true" pauses the updates for a specific addon

## 3.\*

- Breaking change : new logic. Please read Readme.
- Supports sources from : dockerhub/github,gitlab,bitbucket,pip,hg,sf,website-feed,local,helm_chart,wiki,system,wp

## 2.\*

- Add codenotary sign
- Initial build
