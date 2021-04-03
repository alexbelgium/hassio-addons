#!/usr/bin/with-contenv bashio

# wait for scrutiny to load
bashio::net.wait_for 8080

#######################
# VIEWPORT CORRECTION #
#######################

 # correct viewport bug
grep -rl '"lt-md":"(max-width:  959px)"' /app | xargs sed -i 's|"lt-md":"(max-width:  959px)"|"lt-md":"(max-width:  100px)"|g' || true
    
######################
# API URL CORRECTION #
######################

# allow true url for ingress 
grep -rl '/api/' /app | xargs sed -i 's|/api/|api/|g' || true
grep -rl 'api/' /app | xargs sed -i 's|api/|./api/|g' || true

#####################
# ADD LOCAL DEVICES #
#####################

# search for local devices
scrutiny-collector-metrics run >/dev/null && bashio::log.info "Local Devices Added" || bashio::log.error "Local Devices Not Added" 
