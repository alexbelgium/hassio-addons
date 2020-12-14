# Transmission

## About

Transmission is a bittorrent client.
This addon is based on the [docker image](https://github.com/linuxserver/transmission) from linuxserver.io.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences by modying the json file in /share/transmission, see the official documentation for for that.

## Configuration

Options : 
1. "download_dir": "/share/downloads"      # where the files will be saved after download
1. "incomplete_dir": "/share/incomplete"   # where the files are saved during download
1. "localdisks": ["sda1"]                  # list of devices to mount, '' if none
1. "networkdisks": "<//SERVER/SHARE>"      # list of smbv2/3 servers to mount, '' if none
1. "cifsusername": "<username>"            # smb username
1. "cifspassword": "<password>"            # smb password

Webui can be found at `<your-ip>:9091.

[repository]: https://github.com/alexbelgium/hassio-addons
