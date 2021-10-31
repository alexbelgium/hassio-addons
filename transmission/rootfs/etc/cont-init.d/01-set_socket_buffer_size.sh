#!/bin/bash
##########################
# SET_SOCKET_BUFFER_SIZE #
##########################

echo "Setting socket buffer size"
sed -i -e '$a"net.core.rmem_max = 4194304"' /etc/sysctl.conf
sed -i -e '$a"net.core.wmem_max = 1048576"' /etc/sysctl.conf
