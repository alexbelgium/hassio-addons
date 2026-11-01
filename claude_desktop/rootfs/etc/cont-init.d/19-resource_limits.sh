#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Apply the optional cpu_limit / memory_limit options.
#
# Supervisor has no CPU or memory key for add-ons, and `docker update` is lost when it recreates
# the container, so the limits are set on a child cgroup at every start. nsdelegate forbids
# writing cpu.max / memory.max on the container's own cgroup, and a cgroup can only delegate
# controllers once it holds no process, hence moving everything to the child first. This runs
# early because memory already charged stays with the parent.

cpu_limit=""
memory_limit=""
if bashio::config.has_value 'cpu_limit'; then
    cpu_limit="$(bashio::config 'cpu_limit')"
fi
if bashio::config.has_value 'memory_limit'; then
    memory_limit="$(bashio::config 'memory_limit')"
fi
if [[ -z "$cpu_limit" && -z "$memory_limit" ]]; then
    exit 0
fi

cgroup="$(mktemp -d)"
if ! mount -t cgroup2 none "$cgroup"; then
    bashio::log.warning "Could not mount cgroup2: cpu_limit and memory_limit are not applied"
    rmdir "$cgroup"
    exit 0
fi

mkdir -p "$cgroup/addon"
delegated=false
# Retry because processes forked during the move land in the parent and make the write fail
for _ in 1 2 3 4 5; do
    xargs -rn1 < "$cgroup/cgroup.procs" > "$cgroup/addon/cgroup.procs" || true
    if echo "+cpu +memory" 2> /dev/null > "$cgroup/cgroup.subtree_control"; then
        delegated=true
        break
    fi
done

if [[ "$delegated" != true ]]; then
    bashio::log.warning "Could not enable the cgroup v2 controllers: cpu_limit and memory_limit are not applied"
else
    if [[ -n "$cpu_limit" ]]; then
        awk -v cpus="$cpu_limit" 'BEGIN { printf "%.0f 100000\n", cpus * 100000 }' > "$cgroup/addon/cpu.max"
        bashio::log.info "CPU limited to $cpu_limit core(s)"
    fi
    if [[ -n "$memory_limit" ]]; then
        echo "$memory_limit" > "$cgroup/addon/memory.max"
        # As with docker --memory: as much swap again, so idle sessions can still be swapped out
        echo "$memory_limit" > "$cgroup/addon/memory.swap.max"
        bashio::log.info "Memory limited to $memory_limit"
    fi
fi

umount "$cgroup"
rmdir "$cgroup"
