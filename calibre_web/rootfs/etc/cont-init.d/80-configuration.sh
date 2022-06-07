#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# shellcheck disable=SC2015

# Set TZ
if bashio::config.has_value 'TZ'; then
    TIMEZONE=$(bashio::config 'TZ')
    bashio::log.info "Setting timezone to $TIMEZONE"
    ln -snf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime && echo "$TIMEZONE" >/etc/timezone
fi

# Disable session protection 
# https://forums.unraid.net/topic/71927-support-linuxserverio-calibre-web/page/5/#comment-1015352
echo "**** patching calibre-web - removing session protection ****"
sed -i "/lm.session_protection = 'strong'/d" /app/calibre-web/cps/__init__.py || true

bashio::log.info "Default username:password is admin:admin123"
