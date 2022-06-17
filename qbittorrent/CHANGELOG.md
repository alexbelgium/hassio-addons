
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
- Whitelist option
- Enables PUID/GUID options
- Addition of ssl options
- Addition of possibility to mount local disc or smb
