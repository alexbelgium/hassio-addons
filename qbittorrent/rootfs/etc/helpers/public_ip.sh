#!/bin/bash

get_public_ip() {
    local urls=(
        "https://ifconfig.co/ip"
        "https://api64.ipify.org"
        "https://ipecho.net/plain"
    )
    local i j tmp url ip

    # Fisher–Yates shuffle to randomize the order
    for ((i=${#urls[@]}-1; i>0; i--)); do
        j=$((RANDOM % (i + 1)))
        tmp=${urls[i]}
        urls[i]=${urls[j]}
        urls[j]=$tmp
    done

    # Try each provider in random order until one works
    for url in "${urls[@]}"; do
        if ip=$(curl -fsS --max-time 10 "$url"); then
            printf '%s\n' "$ip"
            return 0
        fi
    done

    return 1
}

# Write to /currentip, fail if none of the services respond
if ! get_public_ip > /currentip; then
    echo "Failed to get public IP from all providers" >&2
fi
