## 5.1.2-4 (31-07-2025)
- Support mounting NFS shares https://github.com/alexbelgium/hassio-addons/wiki/Mounting-remote-shares-in-Addons

## 5.1.2-2 (12-07-2025)
- Safety check : check if yify.foo found in qbittorrent.conf

## 5.1.2 (05-07-2025)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 5.1.1 (28-06-2025)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 5.1.0 (10-05-2025)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 5.0.4 (21-02-2025)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 5.0.3 (21-12-2024)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 5.0.2 (23-11-2024)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 5.0.1 (02-11-2024)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 5.0.0-3 (13-10-2024)

- Solve qbittorrent-nox error

## 5.0.0 (05-10-2024)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 4.6.7 (21-09-2024)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 4.6.6 (24-08-2024)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 4.6.5 (01-06-2024)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 4.6.4-2 (19-04-2024)

- Fix nmap bug

## 4.6.4 (30-03-2024)

- Update to latest version from linuxserver/docker-qbittorrent (changelog : https://github.com/linuxserver/docker-qbittorrent/releases)

## 4.6.3-4 (21-01-2024)

- Fix : openvpn not starting https://github.com/alexbelgium/hassio-addons/issues/1192

## 4.6.3 (20-01-2024)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.6.2_43 (12-01-2024)

- Fix : openvpn not starting https://github.com/alexbelgium/hassio-addons/issues/1175

## 4.6.2_42 (12-01-2024)

- Fix : failure to install custom webUI https://github.com/alexbelgium/hassio-addons/issues/1172 (thanks @akrigator)
- [qbit_manage] : switch to develop

## 4.6.2_40 (31-12-2023)

- Minor bugs fixed
- [qbit_manage] : corrects default yaml for the addon for url (127.0.0.1 instead of localhost ) ; username (from username in options) ; password (default is homeassistant) ; root_dir (from SavePath in options) [15f4d63](https://github.com/alexbelgium/hassio-addons/commit/15f4d632c5d6946d093e39b5d3f9bee135aadfe7)

## 4.6.2_37 (30-12-2023)

- [openvpn] Feat (potential breaking change) : previously, "auth-user-pass" fields were removed to use the addon username & password. Now, the addon will respect those fields if the file exists to allow for multiple configurations storing different credentials in local files. If the referenced file doesn't exists, or if this field is not referenced, the normal addon username & password will be used
- [openvpn] Feat : use ovpn files directly in /config/openvpn instead of doing a copy in /etc/openvpn as before. This will make any change more obvious to the user.

## 4.6.2_30 (30-12-2023)

- [openvpn] Feat : sanitize ovpn files (disabling ipv6 as not supported by HA, ensuring CRLF, ensure trailing new line, checking paths of referenced static files...)
- [openvpn] Feat : if no ovpn is referred in the option, it will use a random one from the openvpn folder (from https://github.com/Trigus42/alpine-qbittorrentvpn)
- [qbittorrent] Fix : avoid addon restart at each start (due to blanks being cleaned in the whitelist field)
- [general] Fix : reduce cron log level to avoid spam

## 4.6.2_27_reverted (23-12-2023)

- &#9888; BREAKING CHANGE : I've decided to revert to the initial upstream image, apologies for this whole incovenience. After receiving many constructive (or plainly negative) feedbacks I have decided it was just not worth it to implement a new upstream image supposed to prevent ip leak for openvpn, plus wireguard support, and decided to just restore my own code. I've still kept qbit_manage, and will perhaps implement wireguard in the future but with my own code. As the databases were migrated for users to the new config locations, I've decided to keep it like that. It is more sustainable as HA is pushing in this direction and allows to backup the config with the addon (which was not the case previously).

- &#9888; ACTION (preferred) : Please restore a backup prior to the versions containing wireguard_openvpn in the name, then update (as was mentioned in the 4.6.2-5wireguard_openvpn changelog asking a full backup prior to update). This will make sure all your options are kept and you don't need to reconfigure

- &#9888; IF NO BACKUP : You'll need to update directly, but you'll need to reconfigure the addon (in theory the database should be kept)

## 4.6.2-23_wireguard_openvpn (15-12-2023)

- Perform migration of previous files a single time to allow backup restore prior to the change of image

## 4.6.2-20_wireguard_openvpn (14-12-2023)

- Minor bugs fixed
- Sanitize the ovpn file
- Implement a sleep period to wait until vpn is up on faster systems
- qbit_manage : add run command

## 4.6.2-16_wireguard_openvpn (13-12-2023)

- Minor bugs fixed
- Remove route-nopull to allow upstream scripts
- &#9888; PLEASE READ CHANGELOG OF "4.6.2-5wireguard_openvpn" FIRST
- Correct ssl usage : either with HA certificates or self-generated
- Corrected 00-smb_mounts.sh logic for servers that don't support anonymous access
- Readme : instructions on setting up Jackett as qbittorrent engine

## 4.6.2-5wireguard_openvpn (09-12-2023)

- MAKE A FULL BACKUP BEFORE UPDATING !
- &#9888; BREAKING CHANGE : upstream container switched to trigus42/qbittorrentvpn. All options will be migrated. Please double check all your options as the default behavior might have changed.
- &#9888; BREAKING CHANGE : default password changed from "adminadmin" to "homeassistant". Please change from webui
- &#9888; MAJOR CHANGE : switch to the new config logic from homeassistant. Your configuration files will have migrated from /config/hassio_addons/qBittorrent et a folder only accessible from my Filebrowser addon called /addon_configs/something-qBittorrent. This avoids the addon to mess with your homeassistant configuration folder, and allows to backup the options. Migration of data, custom configs, and custom scripts should be automatic. Please be sure to update all your links however ! For more information, see here : https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/
- FEAT : wireguard support, see trigus42/qbittorrentvpn
- FEAT : addition of qbit_manage application through an addon option. Please customize the configuration file in /config/xxx-qBittorrent/qbit_manage/qbit_manage.yml
- Fix : avoid crond messages spaming https://github.com/alexbelgium/hassio-addons/issues/1111

## 4.6.2 (02-12-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.6.1-6 (22-11-2023)

- Minor bugs fixed

## 4.6.1-5 (22-11-2023)

- Minor bugs fixed
- Selecting qbit webui also applies it to ingress. Otherwise, default is vuetorrent

## 4.6.1-3 (22-11-2023)

- Minor bugs fixed
- Restart the addon after setting the default password

## 4.6.1-2 (22-11-2023)

- Minor bugs fixed
- Re-add default username (admin) and password (homeassistant)

## 4.6.1 (21-11-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.6.0-3 (06-11-2023)

- Minor bugs fixed
- Ingress webui update at start

## 4.6.0-2 (30-10-2023)

- Minor bugs fixed

## 4.6.0-WITHOUT_VPN (30-10-2023)

- Minor bugs fixed

## 4.6.0 (28-10-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.5-4 (30-09-2023)

- Minor bugs fixed
- Avoid crash when using smbv1

## 4.5.5 (02-09-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.4-2 (24-06-2023)

- Minor bugs fixed
- armv7 not supported anymore by linuxserver, it is pinned to latest working version

## 4.5.4 (24-06-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.3-r0-2 (12-06-2023)

- Minor bugs fixed
- Evaluate smb v2 before v1

## 4.5.3-r0 (07-06-2023)

- Minor bugs fixed

## 4.5.3 (03-06-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.2-3 (22-04-2023)

- Minor bugs fixed
- Fix multi smb mounts

## 4.5.2-2 (19-03-2023)

- Minor bugs fixed
- Align exec code with upstream

## 4.5.2 (18-03-2023)

- Update to latest version from linuxserver/docker-qbittorrent
- Correct downloads folder

## 4.5.2-r0-ls250-2 (13-03-2023)

- Minor bug fixes
- Try solving sed error message #755

## 4.5.2-r0-ls250-2 (11-03-2023)

- Bug updates
- Add lsio branding
- Implement healthcheck

## 4.5.2-r0-ls250 (11-03-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.2-r0-ls249 (04-03-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.1-r1-ls246 (25-02-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.1-r1-ls245 (19-02-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.0-r1-ls243 (11-02-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.0-r1-ls242 (04-02-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.0-r1-ls241 (28-01-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.0-r1-ls240 (21-01-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.0-r1-ls239 (14-01-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.0-r1-ls238 (07-01-2023)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.0-r1-ls237 (31-12-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.0-r1-ls236 (25-12-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.0-r0-ls234 (13-12-2022)

- Update to latest version from linuxserver/docker-qbittorrent
- Fix : using options Savepath for download folder

## 4.5.0-r0-ls233 (06-12-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.0-r0-ls232 (01-12-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.5.0-r0-ls231 (29-11-2022)

- Update to latest version from linuxserver/docker-qbittorrent
- WARNING : update to supervisor 2022.11 before installing

## 4.4.5-r3-ls230 (22-11-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r3-ls229 (14-11-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r2-ls227 (08-11-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r2-ls226 (01-11-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r2-ls224 (25-10-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r1-ls223 (20-10-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r0-ls222 (18-10-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r0-ls221 (11-10-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r0-ls219 (04-10-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r0-ls218 (27-09-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r0-ls217 (22-09-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r0-ls216 (20-09-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r0-ls215 (13-09-2022)

- Update to latest version from linuxserver/docker-qbittorrent
- Config folder moved to /config/addons_config/qbittorrent

## 4.4.5-r0-ls214 (09-09-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.5-r0-ls213 (01-09-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3.1-r1-ls211 (30-08-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3.1-r1-ls210 (13-08-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3.1-r1-ls209 (09-08-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3.1-r1-ls208 (04-08-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3.1-r1-ls207 (26-07-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3.1-r1-ls206 (12-07-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3.1-r1-ls205 (05-07-2022)

- Update to latest version from linuxserver/docker-qbittorrent
- Default port changed from 6881 to 59595 ; reset your port settings if it doesn't change

## 4.4.3.1-r1-ls204 (18-06-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3.1-r1-ls201 (14-06-2022)

- Update to latest version from linuxserver/docker-qbittorrent
- Addition of optional noserverino in smb mount code

## 4.4.3.1-r1-ls200 (06-06-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3.1-r1-ls199 (02-06-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3.1-r0-ls198 (31-05-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3-r0-ls197 (26-05-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.3-r0-ls195 (24-05-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.2-r5-ls193 (17-05-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.2-r4-ls191 (10-05-2022)

- Update to latest version from linuxserver/docker-qbittorrent
- Feature : message in log showing if vpn alt mode is working

## 4.4.2-r4-ls190 (03-05-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 4.4.2-r4-ls189 (27-04-2022)

- Update to latest version from linuxserver/docker-qbittorrent
- New feature "silent" : true shows only error messages of qbittorrent and nginx
- New feature "openvpn_alt_mode": bind at container level and not app level
- Add codenotary sign
- Fix openvpn interface bind
- Fix qb-web custom ui
- Fix download folder

## release-4.4.1-ls172 (20-02-2022)

- Update to latest version from linuxserver/docker-qbittorrent
- Complete rebase to alpine
- Fix custom DNS
- Host header validation disabled (avoids ingress issues)
- Removed openvpn_alternative_mode (please delete from config), now default
- Changed openvpn mode to interface binding (no ip leakage)

## 14.3.9.99202110311443-7435-01519b5e7ubuntu20.04.1-ls166 (07-01-2022)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.9.99202110311443-7435-01519b5e7ubuntu20.04.1-ls165 (04-01-2022)

- Update to latest version from linuxserver/docker-qbittorrent
- Removed watchdog
- New standardized logic for Dockerfile build and packages installation
- Allow mounting nvme
- Allow mounting local drives by label. Just pust the label instead of sda1 for example

## 14.3.9.99202110311443-7435-01519b5e7ubuntu20.04.1-ls159 (31-10-2021)

- Update to latest version from linuxserver/docker-qbittorrent
- SMB : accepts several disks separated by commas mounted in /mnt/$sharename

## 14.3.8.99202110120741-7429-1bae770b2ubuntu20.04.1-ls158 (13-10-2021)

- Update to latest version from linuxserver/docker-qbittorrent
- Added watchdog feature

## 14.3.8.99202110081405-7423-ac5c264e6ubuntu20.04.1-ls157 (08-10-2021)

- Update to latest version from linuxserver/docker-qbittorrent
- Allow mounting local drives. Set "localdisks" to your disk name such as sda1
- Added auto stop, just set the run_duration optional setting

## 14.3.8.99202109100310-7422-338d9a084ubuntu20.04.1-ls154 (10-09-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.8.99202108291924-7418-9392ce436ubuntu20.04.1-ls152 (31-08-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.7.99202108230857-7410-fefce0337ubuntu20.04.1-ls151 (24-08-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.7.99202108032349-7395-0415c0c6fubuntu20.04.1-ls149 (05-08-2021)

- Update to latest version from linuxserver/docker-qbittorrent
- Improved smb mount code

## 14.3.6.99202107121017-7389-3ac8c97e6ubuntu20.04.1-ls145 (13-07-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.6.99202107050919-7388-ede42910dubuntu20.04.1-ls143 (05-07-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.6.99202106272003-7387-ac8105c30ubuntu20.04.1-ls141 (28-06-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.5.99202106211645-7376-e25948e73ubuntu20.04.1-ls140 (22-06-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.5.99202106201814-7376-e25948e73ubuntu20.04.1-ls139 (21-06-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.5.99202106191735-7376-e25948e73ubuntu20.04.1-ls138 (20-06-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.5.99202106151345-7374-667d4e421ubuntu20.04.1-ls137 (16-06-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.5.99202106080759-7366-33e090cfcubuntu20.04.1-ls136 (09-06-2021)

- Update to latest version from linuxserver/docker-qbittorrent
- Add banner in log
- New option openvpn_alternative_mode, binds only ovpn to qbittorrent and not webui

## 14.3.5.99202105022253-7365-063844ed4ubuntu20.04.1-ls133 (11-05-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.5.99202105022253-7365-063844ed4ubuntu20.04.1-ls132 (04-05-2021)

- Update to latest version from linuxserver/docker-qbittorrent
- New option : use specific DNS instead of the router ones to avoid spamming, especially useful if using adguard home/pihole. Keep blank to use the router dns.

## 14.3.4.99202104300534-7354-9f8a6e8fbubuntu20.04.1-ls131 (01-05-2021)

- Update to latest version from linuxserver/docker-qbittorrent
- Robust the smb script to test for several common options
- smbv1 bit is not used anymore

## 14.3.4.99202104281424-7353-7dd9e7343ubuntu20.04.1-ls130 (29-04-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.4.99202104250604-7352-b2a43eeffubuntu20.04.1-ls129 (27-04-2021)

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.4.99202104250604-7352-b2a43eeffubuntu20.04.1-ls128

- Update to latest version from linuxserver/docker-qbittorrent
- Clarified steps to check in case of smb mount fail
- New option : set domain for smb share
- Addition of openvpn support

## 14.3.4.99202104180633-7350-2c8f322afubuntu20.04.1-ls127

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.4.99202104090418-7349-789803700ubuntu20.04.1-ls126

- Update to latest version from linuxserver/docker-qbittorrent
- Addition of ingress
- Viewtorrent as default ui

## 14.3.4.99202104031018-7348-2b6baa609ubuntu20.04.1-ls125

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.3.99202103251603-7345-332b173e0ubuntu20.04.1-ls122

- Update to latest version from linuxserver/docker-qbittorrent ; Rebase to focal.

## 14.3.3.99202101191832-7248-da0b276d5ubuntu20.04.1-ls120

- Update to latest version from linuxserver/docker-qbittorrent ; Stop creating /config/data directory on startup

## 14.3.3.99202101191832-7248-da0b276d5ubuntu20.04.1-ls119

- Update to latest version from linuxserver/docker-qbittorrent ; Fix adding search engine plugin

## 14.3.3.99202101191832-7248-da0b276d5ubuntu20.04.1-ls118

- Update to latest version from linuxserver/docker-qbittorrent
- Allow mounting shares named \ip\share in addition to //ip/share

## 14.3.3.99202101191832-7248-da0b276d5ubuntu20.04.1-ls117

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.3.99202101191832-7248-da0b276d5ubuntu20.04.1-ls116

- Correct VueTorrent link

## 14.3.3.99202101191832-7248-da0b276d5ubuntu20.04.1-ls115

- New configuration option : set download path
- New configuration option : set username for webUI
- New feature : mount smb share in protected mode
- New feature : mount multiple smb shares
- New config/feature : mount smbv1
- Changed path : changed smb mount path from /storage/externalcifs to /mnt/$NAS name
- Removed feature : ability to remove protection and mount local hdd, to increase the addon score
- Update to latest version from linuxserver/docker-qbittorrent
- Enabling of custom webUI from configuration

## 14.3.3.99202101191832-7248-da0b276d5ubuntu18.04.1-ls114

- Update to latest version from linuxserver/docker-qbittorrent

## 14.3.3.99202101191832-7248-da0b276d5ubuntu18.04.1-ls113

- Update to latest version from linuxserver/docker-qbittorrent
- LAN_NETWORK option
- Enables PUID/PGID options
- Addition of ssl options
- Addition of possibility to mount local disc or smb
