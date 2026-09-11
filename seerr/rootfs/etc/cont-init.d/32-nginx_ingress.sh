#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

####################
# Seerr Ingress    #
####################

bashio::log.info "Configuring Nginx for ingress..."

ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
ingress_entry=$(bashio::addon.ingress_entry)

# Cache-busting marker for the rewritten JavaScript bundle.
#
# Seerr serves /_next/static/ as "public, max-age=31536000, immutable", and
# nginx's sub_filter strips ETag and Last-Modified off every response it
# rewrites, while the HTML naming those chunks is served "no-store" and keeps
# naming the same URLs. A browser therefore pins the bundle this add-on rewrote
# on its first visit for a year, with no request left that could deliver a
# later change to the sub_filter rules below - which is how #2975 outlived two
# fixes. Folding the version into the asset path gives every release its own
# URLs. njs/ingress.js strips the marker again before proxying.
#
# BUILD_VERSION is the add-on version baked in at build time (it is also what
# bashio::addon.version returns). Only [A-Za-z0-9-] survives: the marker ends up
# inside a regex literal in Seerr's own bundle, where a dot would be a wildcard.
asset_tag="ha-$(printf '%s' "${BUILD_VERSION:-0}" | tr -c 'A-Za-z0-9' '-')"

# Update ingress.conf with actual values
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry_escaped%%|${ingress_entry//\//\\\\\/}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%asset_tag%%|${asset_tag}|g" /etc/nginx/servers/ingress.conf

bashio::log.info "Nginx ingress configured on ${ingress_interface}:${ingress_port} (asset tag ${asset_tag})"
