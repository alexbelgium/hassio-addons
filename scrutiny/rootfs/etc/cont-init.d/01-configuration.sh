#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

#################
# Create folder #
#################

DATABASELOCATION="/data"
echo "Updating folders structure"
mkdir -p "$DATABASELOCATION"/config
mkdir -p "$DATABASELOCATION"/influxdb
if [ -d /opt/scrutiny/config ]; then rm -r /opt/scrutiny/config; fi
if [ -d /opt/scrutiny/influxdb ]; then rm -r /opt/scrutiny/influxdb; fi
ln -s "$DATABASELOCATION"/config /opt/scrutiny
ln -s "$DATABASELOCATION"/influxdb /opt/scrutiny

###############################
# Migrating previous database #
###############################

if [ -f /data/scrutiny.db ]; then
    bashio::log.warning "Previous database detected, migration will start. Backup stored in /share/scrutiny.db.bak"
    cp /data/scrutiny.db /share/scrutiny.db.bak
    mv /data/scrutiny.db "$DATABASELOCATION"/config/
fi

######
# TZ #
######

# Align timezone with options
if bashio::config.has_value "TZ"; then
    TZ="$(bashio::config 'TZ')"
    bashio::log.info "Timezone : $TZ"
    sed -i "1a export TZ=$TZ" /etc/cont-init.d/01-timezone
fi

################
# CRON OPTIONS #
################

# Align update with options
FREQUENCY="$(bashio::config 'Updates')"
bashio::log.info "$FREQUENCY updates as defined in the 'Updates' option"

case "$FREQUENCY" in
    "Quarterly")
        sed -i "/customize the cron schedule/a export COLLECTOR_CRON_SCHEDULE=\"*/15 * * * *\"" /etc/cont-init.d/50-cron-config
        ;;

    "Hourly")
        sed -i "/customize the cron schedule/a export COLLECTOR_CRON_SCHEDULE=\"0 * * * *\"" /etc/cont-init.d/50-cron-config
        ;;

    "Daily")
        sed -i "/customize the cron schedule/a export COLLECTOR_CRON_SCHEDULE=\"0 0 * * *\"" /etc/cont-init.d/50-cron-config
        ;;

    "Weekly")
        sed -i "/customize the cron schedule/a export COLLECTOR_CRON_SCHEDULE=\"0 0 * * 0\"" /etc/cont-init.d/50-cron-config
        ;;

    "Custom")
        interval="$(bashio::config 'Updates_custom_time')"
        bashio::log.info "... frequency is defined manually as $interval"

        case "$interval" in
            *m) # Matches intervals in minutes, like "5m" or "30m"
                minutes="${interval%m}"
                if [[ "$minutes" -gt 0 && "$minutes" -le 59 ]]; then
                    cron_schedule="*/$minutes * * * *"
    else
                    bashio::log.error "Invalid minute interval: $interval"
    fi
                ;;

            *h) # Matches intervals in hours, like "2h"
                hours="${interval%h}"
                if [[ "$hours" -gt 0 && "$hours" -le 23 ]]; then
                    cron_schedule="0 */$hours * * *"
    else
                    bashio::log.error "Invalid hour interval: $interval"
    fi
                ;;

            *w) # Matches intervals in weeks, like "1w"
                weeks="${interval%w}"
                if [[ "$weeks" -gt 0 && "$weeks" -le 4 ]]; then
                    cron_schedule="0 0 * * 0" # Weekly on Sunday (adjust if needed for multi-week)
    else
                    bashio::log.error "Invalid week interval: $interval"
    fi
                ;;

            *mo) # Matches intervals in months, like "1mo"
                months="${interval%mo}"
                if [[ "$months" -gt 0 && "$months" -le 12 ]]; then
                    cron_schedule="0 0 1 */$months *" # Monthly on the 1st
    else
                    bashio::log.error "Invalid month interval: $interval"
    fi
                ;;

            *)
                bashio::log.error "Empty or unsupported custom interval. It should be in the format of 5m (every 5 minutes), 10d (every 10 days), 3w (every 3 weeks), 3mo (every 3 months)"
                ;;
  esac

        if [[ -n "$cron_schedule" ]]; then
            sed -i "/customize the cron schedule/a export COLLECTOR_CRON_SCHEDULE=\"$cron_schedule\"" /etc/cont-init.d/50-cron-config
            bashio::log.info "Custom cron schedule set to: $cron_schedule"
  fi
        ;;
esac
