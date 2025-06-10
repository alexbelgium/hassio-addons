#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

###############
# DNS SETTING #
###############

# Avoid usage of local dns such as adguard home or pihole\n"

if bashio::config.has_value 'DNS_server'; then
  # Define variables
  DNSSERVER=$(bashio::config 'DNS_server')
  DNS=""
  DNSLIST=""

  # Get DNS servers
  # shellcheck disable=SC2086
  for server in ${DNSSERVER//,/ }; do # Separate comma separated values
    # Only add DNS if successful
    if ping -c 1 "$server" &>/dev/null; then
      DNS="${DNS}nameserver $server\n"
      DNSLIST="$server $DNSLIST"
    else
      bashio::log.warning "DNS $server was requested but can't be pinged. It won't be used"
    fi
  done

  # Only add DNS if there are DNS set
  # shellcheck disable=SC2236
  if [[ -n "${DNS:-}" ]]; then
    # Write resolv.conf
    # shellcheck disable=SC2059
    printf "${DNS}" >/etc/resolv.conf
    chmod 644 /etc/resolv.conf
    bashio::log.info "DNS SERVERS set to $DNSLIST"
  else
    bashio::log.warning "No valid DNS were found. Using default router (or HA) dns servers."
  fi

else
  bashio::log.info "DNS Servers option empty. Using default router (or HA) dns servers."
fi
