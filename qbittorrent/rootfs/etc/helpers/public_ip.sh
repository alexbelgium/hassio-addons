#!/usr/bin/env bash
# get-public-ip: query several IP services in random order and print the first result

set -euo pipefail

get_public_ip() {
    local -a urls=(
        "https://ifconfig.co/ip"
        "https://api64.ipify.org"
        "https://ipecho.net/plain"
    )
    local ip=""
    local i=0
    local j=0
    local tmp=""

    # Fisher–Yates shuffle to randomize order
    for ((i=${#urls[@]}-1; i>0; i--)); do
        j=$((RANDOM % (i + 1)))
        tmp=${urls[i]}
        urls[i]=${urls[j]}
        urls[j]=$tmp
    done

    # Try each provider in random order until one works
    for url in "${urls[@]}"; do
        # Suppress curl error messages
        if ip=$(curl -fsS --max-time 10 "$url" 2>/dev/null); then
            printf '%s\n' "$ip"
            return 0
        fi
    done

    return 1
}

if ! get_public_ip; then
    echo "get-public-ip: failed to get public IP from all providers" >&2
    exit 1
fi
