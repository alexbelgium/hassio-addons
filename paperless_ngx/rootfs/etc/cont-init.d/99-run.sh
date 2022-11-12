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

if [ ! -f /data/adminuser ]; then

# Store last line
LASTLINE="$(tail -1 /usr/local/bin/paperless_cmd.sh)"

# Delete last line
sed -i '$d' /usr/local/bin/paperless_cmd.sh

# Append user creation
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
EOF" >> /usr/local/bin/paperless_cmd.sh

# Restore last line
echo "$LASTLINE" >> /usr/local/bin/paperless_cmd.sh

# Say admin created
touch /data/adminuser

fi

bashio::log.info "Initial username and password are admin. Please change in the administration panel of the webUI after login."
