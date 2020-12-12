[![](logo.png)](https://nextcloud.com/)

# Nextcloud

Nextcloud Home Assistant add-on

# How to use this add-on

Install the add-on, choose your desired port, start.

After the add-on is started proceed to: https://[ip]:[port] and follow the setup process.

# How to add trusted domain
Nextcloud requires a whitelist of trusted domains in order to access Nextcloud externally, or even internally from an address that is different from the domain it is initially assessed from. Normally this requires editing of a config file. If you have access to the add-on data storage (i.e. Supervised Installation) then the recommended method is to follow official documentation to add your domain. 

If you are running HASSOS and have no access to edit this file you can add your domain from the web interface through a console app that allows access to the 'occ' command line.

To do this, log into the Nextcloud web interface as an admin user, click the top right user image icon to expand the menu. Select the Apps to go to the app installation page. On the app installation page install an app called 'OCC Web'.

Once installed return to the main page and launch OCCWeb.

When the console is displayed type:

> config:system:get trusted_domains

Warning: overwriting the domain you are currently using will make Nextcloud inaccessible and the add-on will have to be deleted and reinstalled. This will list the current trusted domains. The domains are numbered from 0 so if you have two domains that display the first is domain 0, the second is domain 1. To add another domain:

> config:system:set trusted_domains 2 --value=my.domain.com

Where the number 2 is the now new third domain position in the config file, and 'my.domain.com' is your domain. Type the first command again to see whether the new domain has indeed been added. If it has, you are done!

Based on the linuxserver image
