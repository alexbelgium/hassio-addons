# BirdNET-Pi Docker Installation Guide

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

This guide provides instructions on how to install and run the BirdNET-Pi container using Docker Compose without dependency on HomeAssistant.

_Note : For usage as an HomeAssistant addon, see [here](https://github.com/alexbelgium/hassio-addons/blob/master/birdnet-pi/README.md)_

Thanks to @gotschi for the initial Docker Compose

## Prerequisites

Ensure you have the following installed on your system:
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Installation

1. **Create a directory for BirdNET-Pi**
   ```sh
   mkdir -p ~/birdnet-pi && cd ~/birdnet-pi
   ```

2. **Create a `docker-compose.yml` file**
   Create and open the file with:
   ```sh
   nano docker-compose.yml
   ```

   Copy and paste the following configuration:
   ```yaml
   services:
     birdnet-pi:
       container_name: birdnet-pi
       image: ghcr.io/alexbelgium/birdnet-pi-amd64:latest # or ghcr.io/alexbelgium/birdnet-pi-aarch64:latest depending on your system
       restart: unless-stopped
       ports:
         - "8001:8081"  # Used to access WebUI
         - "80:80"  # Optional: set to 80 to use Caddy's automatic SSL. Can otherwise be set to null to avoid opening an additional port
       environment:
         - TZ=Europe/Vienna  # Optional: Set your timezone according to https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
         - BIRDSONGS_FOLDER=/config/BirdSongs  # Folder to store bird songs, be sure to use a path that is mapped to a volume (such as /config)
         - LIVESTREAM_BOOT_ENABLED=false  # Enable/disable livestream on boot
         - ssl=false  # Enable/disable SSL
         - certfile=fullchain.pem  # SSL certificate file (located in /ssl/)
         - keyfile=privkey.pem  # SSL key file (located in /ssl/)
         - pi_password=  # Optional: Set SSH user password
         - MQTT_HOST_manual=  # Optional: Manual MQTT host
         - MQTT_PASSWORD_manual=  # Optional: Manual MQTT password
         - MQTT_PORT_manual=  # Optional: Manual MQTT port
         - MQTT_USER_manual=  # Optional: Manual MQTT user
       volumes:
         - ./config:/config  # All your configuration files - and location of the default Birdsongs folder
         - ./ssl:/ssl  # SSL certificates
         - /dev/shm:/dev/shm  # Shared memory
       tmpfs:
         - /tmp # Optional
   ```

3. **Start the Container**
   Run the following command in the same directory as `docker-compose.yml`:
   ```sh
   docker compose up -d
   ```
   This will start the BirdNET-Pi container in detached mode.

4. **Access BirdNET-Pi Web UI**
   Open your browser and navigate to:
   ```sh
   http://localhost:8001 # Or whatever port you have configured
   ```
   Replace `localhost` with your server's IP address if running on another machine.

## troubleshoot

If rtsp feed doesn't work, perhaps you need to add "-rtsp-transport tcp" to your ffmpeg instruction, or allow udp on your network

## Updating to the Latest Version

To check for new versions of the container and update:

1. **Check for the latest version**
   Visit the container registry:
   [https://github.com/alexbelgium/hassio-addons/pkgs/container/birdnet-pi-amd64](https://github.com/alexbelgium/hassio-addons/pkgs/container/birdnet-pi-amd64)

   The latest version tag (e.g., `2025.02.23`) will be listed.

2. **Update and restart the container**
   Run the following commands:
   ```sh
   docker compose pull birdnet-pi
   docker compose up -d --force-recreate
   ```
   This pulls the latest image and restarts the container.

3. **Verify the update**
   ```sh
   docker images | grep birdnet-pi
   ```
   This will show the latest downloaded image version.

## Stopping and Removing the Container

To stop and remove the container, run:
```sh
docker compose down
```

This will stop and remove BirdNET-Pi while keeping the configuration and recorded songs intact.

---

Now you're all set to enjoy BirdNET-Pi with Docker! 🐦
