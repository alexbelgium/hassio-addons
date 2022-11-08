#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#################
# Staring redis #
#################
exec redis-server & bashio::log.info "Starting redis"

###########################
# Avoid overcommit memory #
###########################
bashio::log.info "Avoid overcommit memory"
echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf || true

###############################
# Create user if not existing #
###############################
# Origin : https://github.com/linuxserver/docker-paperless-ngx/blob/main/root/etc/cont-init.d/99-migrations
bashio::log.info "Creating default user"
cat << EOF | python3 $(find /app -name manage.py) shell
from django.contrib.auth import get_user_model

# see ref. below
UserModel = get_user_model()

if len(UserModel.objects.all()) == 1:
    print("Creating new user")
    user = UserModel.objects.create_user('admin', password='admin')
    user.is_superuser = True
    user.is_staff = True
    user.save()
EOF

#########
# Start #
#########
bashio::log.info "Initial username and password are admin. Please change in the administration panel of the webUI after login."
