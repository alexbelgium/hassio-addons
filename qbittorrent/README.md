# Home assistant add-on: qbittorrent

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Supports 
 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]
![Supports smb mounts][smb-shield] ![Supports openvpn][openvpn-shield] ![Supports ingress][ingress-shield] ![Supports ssl][ssl-shield]

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

---

[Qbittorrent](https://github.com/qbittorrent/qBittorrent) is a cross-platform free and open-source BitTorrent client.
This addon is based on the docker image from [linuxserver.io](https://www.linuxserver.io/).

This addons has several configurable options :

- allowing to mount local external drive, or smb share from the addon
- [alternative webUI](https://github.com/qbittorrent/qBittorrent/wiki/List-of-known-alternate-WebUIs)
- usage of ssl
- ingress
- optional openvpn support
- allow setting specific DNS servers

## Installation

---

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and adapt the software options

## Configuration

---

Webui can be found at <http://your-ip:8080>, or in your sidebar using Ingress.
The default username/password : described in the startup log.
Configurations can be done through the app webUI, except for the following options

Network disk is mounted to /mnt/share name

```yaml
GUID: user
GPID: user
ssl: true/false
certfile: fullchain.pem #ssl certificate, must be located in /ssl
keyfile: privkey.pem #sslkeyfile, must be located in /ssl
whitelist: "localhost,192.168.0.0/16" # list ip subnets that won't need a password (optional)
Username: "admin" #username to access webui. Please change it as the default is admin for all installations.
customUI: selection from list # alternative webUI can be set here. Latest version set at each addon start.
DNS_servers : 8.8.8.8,1.1.1.1 # Keep blank to use router’s DNS, or set custom DNS to avoid spamming in case of local DNS ad-remover
SavePath: "/share/qbittorrent" # Define the download directory
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. Ex: sda1, sdb1, MYNAS...
networkdisks: "//SERVER/SHARE" # optional, list of smb servers to mount, separated by commas
cifsusername: "username" # optional, smb username, same for all smb shares
cifspassword: "password" # optional, smb password
cifsdomain: "domain" # optional, allow setting the domain for the smb share
openvpn_enabled: true/false # is openvpn required to start qbittorrent
openvpn_alternative_mode: true/false # if enabled, will tunnel only qbittorrent and not webui through vpn. Allows webui connection from external networks, but risk of decreased stability.
openvpn_config": For example "config.ovpn" # name of the file located in /config/openvpn.
openvpn_username": USERNAME
openvpn_password: YOURPASSWORD
run_duration: 12h #for how long should the addon run. Must be formatted as number + time unit (ex : 5s, or 2m, or 12h, or 5d...)
```

## Integration with HA

Use the [qBittorrent integration](https://www.home-assistant.io/integrations/qbittorrent/)

## Support

Create an issue on github, or ask on the [home assistant thread](https://community.home-assistant.io/t/home-assistant-addon-qbittorrent/279247)

## Illustration (vuetorrent webui)

---

![illustration](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/qbittorrent/illustration.png)

[repository]: https://github.com/alexbelgium/hassio-addons
[smb-shield]: https://img.shields.io/badge/smb-yes-green.svg
[openvpn-shield]: https://img.shields.io/badge/openvpn-yes-green.svg
[ingress-shield]: https://img.shields.io/badge/ingress-yes-green.svg
[ssl-shield]: https://img.shields.io/badge/ssl-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
