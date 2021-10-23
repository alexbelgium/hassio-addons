#!/usr/bin/with-contenv bashio

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
    for server in ${DNSSERVER//,/ }  # Separate comma separated values
      do
        DNS="${DNS}nameserver $server\n"
        DNSLIST="$server $DNSLIST"
      done

    # Write resolv.conf
    printf "${DNS}" > /etc/resolv.conf
    chmod 644 /etc/resolv.conf
    bashio::log.info "DNS SERVERS set to $DNSLIST"
else
    bashio::log.info "DNS Servers option empty. Using default router (or HA) dns servers."
fi
