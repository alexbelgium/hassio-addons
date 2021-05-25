# Home assistant add-on: qBittorrent
![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]
![Supports smb mounts][smb-shield] ![Supports openvpn][openvpn-shield] ![Supports ingress][ingress-shield] ![Supports ssl][ssl-shield]

## About

qBittorrent is a bittorrent client.
This addon is based on the [docker image](https://github.com/linuxserver/qbittorrent) from linuxserver.io.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

## Configuration
Webui can be found at <http://your-ip:8081>. The default username/password : described in the startup log. Configurations can be done through the app, except for the following options.

Network disk is mounted to /mnt/storagename

OpenVPN must be enabled from within qBittorrent options

```yaml
GUID: user
GPID: user
ssl: true/false
certfile: fullchain.pem #ssl certificate
keyfile: privkey.pem #sslkeyfile
whitelist: "localhost,192.168.0.0/16" # list ip subnets that won't need a password (optional)
Username: "admin" #username to access webui. Please change it as the default is admin for all installations. 
customUI: selection from list # alternative webUI can be set here. Latest version set at each addon start.
SavePath: "/share/qbittorrent" # Define the download directory
DNS_servers : 8.8.8.8,1.1.1.1 # Keep blank to use router’s DNS, or set custom DNS to avoid spamming in case of local DNS ad-remover
networkdisks: "//SERVER/SHARE" # optional, list of smb servers to mount, separated by commas
cifsusername: "username" # optional, smb username, same for all smb shares
cifspassword: "password" # optional, smb password, same for all smb shares)
openvpn_enabled: yes/no
openvpn_alternative_mode: true/false # if enabled, will tunnel only qbittorrent and not webui through vpn. Allows webui connection from external networks, but risk of decreased stability. 
openvpn_config: must reference an openvpn config files stored in /config/openvpn
openvpn_username: openvpn username
openvpn_password": openvpn password
```

## Support
Create an issue on github, or ask on the [home assistant thread](https://community.home-assistant.io/t/home-assistant-addon-qbittorrent/279247)

[repository]: https://github.com/alexbelgium/hassio-addons
[smb-shield]: https://img.shields.io/badge/smb-yes-green.svg
[openvpn-shield]: https://img.shields.io/badge/openvpn-yes-green.svg
[ingress-shield]: https://img.shields.io/badge/ingress-yes-green.svg
[ssl-shield]: https://img.shields.io/badge/ssl-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
