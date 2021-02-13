#!/bin/bash

scrutiny-collector-metrics run \
|| bashio::log.error "Privileged mode is disabled, the addon will stop"; \
s6-svscanctl -t /var/run/s6/services
