
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
