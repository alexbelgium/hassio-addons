Instructions to migrate to the 2 addons system below.
Please backup all your data, and migrate to the new addons with separate Frontend and API.

## Migrating from <1.0 (aarch64) :

1. Backup all your data from this addon
2. Install the Mealie API addon
3. Configure your base url if needed, and launch it
4. Install the Mealie Frontend addon
5. Configure the API endpoint (make sure to use the addon port of the API addon)
6. Login with the default passwords (Username: changeme@email.com, Password: MyPassword)
7. Import the database
8. Uninstall the previous addon

## Migrating from >1.0 (amd64) (thanks @jdeath) :

While you cannot update from >1.0 to the new version, you can move your database.
1. Start new API and front end addon.
2. Stop new API and front end addon
3. Start the old mealie addon, log in to the docker container, and cp -r /data/* /config/addons_config/mealie_data/
4. Start new API and front end addon, and everything should be working
