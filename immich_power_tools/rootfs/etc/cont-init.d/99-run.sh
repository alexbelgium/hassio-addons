#!/usr/bin/env bashio

bashio::log.info "Starting Immich Power Tools"

# Ensure DB_HOST has no proto in front
extract_ip_or_domain() {
	local url="$1"
	if [[ ! "$url" =~ ^https?:// ]]; then
		bashio::log.warning "URL $url has a http:// or https:// prefix. This should not be, it is removed automatically"
		echo "$url" | sed -E 's|https?://([^/]+).*|\1|'
	fi
}
DB_HOST="$(extract_ip_or_domain "$DB_HOST")"
export DB_HOST

# Function to ensure URL has http:// or https:// prefix
ensure_http_prefix() {
	local url="$1"
	if [[ ! "$url" =~ ^https?:// ]]; then
		bashio::log.warning "URL $url does not have http:// or https:// prefix. Adding http:// by default. If cannot connect to immich, please adapt in your addon options"
		echo "http://$url"
	else
		echo "$url"
	fi
}

# Ensure IMMICH_URL and EXTERNAL_IMMICH_URL have http:// or https:// prefix
IMMICH_URL="$(ensure_http_prefix "$IMMICH_URL")"
export IMMICH_URL
EXTERNAL_IMMICH_URL="$(ensure_http_prefix "$EXTERNAL_IMMICH_URL")"
export EXTERNAL_IMMICH_URL

sudo -u nextjs node server.js
