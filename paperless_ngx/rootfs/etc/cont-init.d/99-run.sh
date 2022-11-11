#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

#################
# Staring redis #
#################
exec redis-server & bashio::log.info "Starting redis"

###############################
# Create user if not existing #
###############################
# Origin : https://github.com/linuxserver/docker-paperless-ngx/blob/main/root/etc/cont-init.d/99-migrations

echo "# Creating user admin
cat << EOF | python3 manage.py shell
from django.contrib.auth import get_user_model

# see ref. below
UserModel = get_user_model()

if len(UserModel.objects.all()) == 1:
    print('Creating new user')
    user = UserModel.objects.create_user('admin', password='admin')
    user.is_superuser = True
    user.is_staff = True
    user.save()
EOF" >> /sbin/docker-entrypoint.sh

bashio::log.info "Initial username and password are admin. Please change in the administration panel of the webUI after login."
