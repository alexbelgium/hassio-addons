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
# Seerr serves everything under /_next/static/ with
# "Cache-Control: public, max-age=31536000, immutable", and nginx's sub_filter
# strips ETag, Last-Modified and Content-Length from every response it rewrites.
# A browser therefore pins the *rewritten* bundle for a year with no way to
# revalidate it, while the HTML that references those chunks is served
# "no-store" and keeps naming the very same chunk URLs. Any later change to the
# sub_filter rules in ingress.conf is then undeliverable: the browser answers
# every chunk request from its own disk cache and never asks this add-on again.
# That is how #2975 survived two shipped fixes - the reporter kept running the
# broken 3.4.1/3.4.1.1 JavaScript out of cache on the origin they use daily.
#
# Folding the add-on version into the asset path gives every release its own set
# of asset URLs, so the first page load after an update misses the cache and
# fetches the current bundle. njs/ingress.js strips the marker again before the
# request is proxied, so Seerr still sees /_next/... exactly as it serves it.
addon_version="$(bashio::addon.version 2>/dev/null || true)"
[ -n "${addon_version}" ] || addon_version="${BUILD_VERSION:-0}"
# Only [A-Za-z0-9-] survives: the marker ends up inside a regex literal in
# Seerr's own bundle (Next.js builds one to strip the /_next/data/ prefix), and
# a dot there would be a wildcard.
asset_tag="ha-$(printf '%s' "${addon_version}" | tr -c 'A-Za-z0-9' '-')"
# A version made only of separators would sanitise away to a bare "ha-",
# which njs/ingress.js would not recognise and so would forward unstripped.
[ "${asset_tag}" != "ha-" ] || asset_tag="ha-0"

# Update ingress.conf with actual values
sed -i "s|%%port%%|${ingress_port}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%interface%%|${ingress_interface}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry%%|${ingress_entry}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%ingress_entry_escaped%%|${ingress_entry//\//\\\\\/}|g" /etc/nginx/servers/ingress.conf
sed -i "s|%%asset_tag%%|${asset_tag}|g" /etc/nginx/servers/ingress.conf

bashio::log.info "Nginx ingress configured on ${ingress_interface}:${ingress_port} (asset tag ${asset_tag})"
