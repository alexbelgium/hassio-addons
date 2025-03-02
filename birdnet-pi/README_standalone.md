# BirdNET-Pi Docker Installation Guide

This guide provides instructions on how to install and run the BirdNET-Pi container using Docker Compose without dependency on HomeAssistant.

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
         - TZ=Europe/Vienna  # Optional, for timezone setting
         - BIRDSONGS_FOLDER=/config/BirdSongs  # Where songs are stored
         - LIVESTREAM_BOOT_ENABLED=false  # If true
         - ssl=false  # In lowercase
         - certfile=fullchain.pem  # Should be located in /ssl/ to use external certificates
         - keyfile=privkey.pem  # Should be located in /ssl/ to use external certificates
         - pi_password=  # Optional, set the user password in SSH
         - MQTT_HOST_manual=  # Optional, allows automatic MQTT
         - MQTT_PASSWORD_manual=  # Optional, allows automatic MQTT
         - MQTT_PORT_manual=  # Optional, allows automatic MQTT
         - MQTT_USER_manual=  # Optional, allows automatic MQTT
       volumes:
         - ./config:/config
         - ./ssl:/ssl
         - /dev/shm:/dev/shm  # Shared memory
   ```

3. **Start the Container**
   Run the following command in the same directory as `docker-compose.yml`:
   ```sh
   docker compose up -d
   ```
   This will start the BirdNET-Pi container in detached mode.

4. **Access BirdNET-Pi Web UI**
   Open your browser and navigate to:
   ```
   http://localhost:8001 # Or whatever port you have configured
   ```
   Replace `localhost` with your server's IP address if running on another machine.

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
