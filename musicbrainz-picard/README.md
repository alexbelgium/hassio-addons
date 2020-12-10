# Docker for musicbrainz-picard

Container for MusicBrainz - [[Picard](https://picard.musicbrainz.org/)] https://picard.musicbrainz.org/

Run MusicBrainz Picard X app embedded in a containter with HTTP GUI (port 5800) or VNC (port 5900) export from [[Jlesage - Docker-baseimage-gui](https://github.com/jlesage/docker-baseimage-gui)] https://github.com/jlesage/docker-baseimage-gui Thanks for the image :P

## Usage
Run the container:
* allow remote access through HTTP GUI. Connect to `http://<docker_ip>:5800`
* allow remote access through VNC Client. Connect to `<docker_ip>:5900`

## Parameters
|Variable|Description|Default|
|:-|:-|-:|
|`-e USER_ID=PUID`|UserID|1000
|`-e GROUP_ID=PGID`|GroupID|1000
|`-e TAKE_CONFIG_OWNERSHIP=1`| When set to 1, owner and group of /config (including all its files and subfolders) are automatically set during container startup to USER_ID and GROUP_ID respectively.|1
|`-e CLEAN_TMP_DIR=1`|When set to 1, all files in the /tmp directory are delete during the container startup.|1
|`-e SECURE_CONNECTION=1`|When set to 1, an encrypted connection is used to access the application's GUI (either via web browser or VNC client).|1
|`-e VNC_PASSWORD=password`|Password needed to connect to the application's GUI.|As you wish
|`-p 5800:5800`| Port HTTP|5800
|`-p 5900:5900`| Port VNC|5900
|`-v ${VOLUME_CONFIG}=/config`| Path to keep config app in a volumen| ./

## Volumen
All files in the container or application are configured to be saved in the path /config

To make the music accessible from inside the container, you can create another volume with the files to be process persistently. For example `-v /music=/config/home/Music`

### Example RUN

docker run -e USER_ID=1000 -e GROUP_ID=1000 -e TAKE_CONFIG_OWNERSHIP=1 -e CLEAN_TMP_DIR=1 -e SECURE_CONNECTION=1 -p 5800:5800 -v ./config=/config -v /music=/config/home/Music elgranloky/musicbrainz-picard
