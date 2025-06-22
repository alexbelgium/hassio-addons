#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Runs only after initialization done
# shellcheck disable=SC2128
if [ ! -f /app/www/public/occ ]; then cp /etc/cont-init.d/"$(basename "${BASH_SOURCE}")" /scripts/ && exit 0; fi

# Install specific packages
if [ ! -d /data/config/www/nextcloud/apps/pdfannotate ]; then
	CURRENT="$PWD"
	cd /data/config/www/nextcloud/apps || exit
	git clone https://gitlab.com/nextcloud-other/nextcloud-annotate pdfannotate
	cd "$CURRENT" || exit
	apk add --no-cache ghostscript >/dev/null
	echo "Nextcloud annotate app added to Nextcloud app store"
fi

# Install specific apps
if bashio::config.has_value 'additional_apps'; then
	bashio::log.info "Installing additional apps :"
	NEWAPPS="$(bashio::config 'additional_apps')"
	OIFS=$IFS
	IFS=","
	re='^( *).*'
	read -ra array <<<"$NEWAPPS"
	IFS=$OIFS
	for element in "${array[@]}"; do
		if [[ $element =~ $re ]]; then
			# shellcheck disable=SC2295
			APP="${element#${BASH_REMATCH[1]}}"
			bashio::log.green "... $APP"
			# shellcheck disable=SC2015,SC2086
			apk add --no-cache $APP >/dev/null || bashio::log.red "... not successful, please check $APP package name"
		fi
	done
fi
