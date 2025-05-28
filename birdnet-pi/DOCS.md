# Microphone considerations

The critical element is the microphone quality: a Boya By-lm 40 or Clippy EM272 (with a very good aux-usb converter) is key to improve the quality of detections.

Here are some example tests I did (the whole threads are really interesting also):

- <https://github.com/mcguirepr89/BirdNET-Pi/discussions/39#discussioncomment-9706951>
- <https://github.com/mcguirepr89/BirdNET-Pi/discussions/1092#discussioncomment-9706191>

**My recommendation:**

- **Best entry system (< 50 €):** Boya By-lm40 (30 €) + deadcat (10 €)
- **Best middle end system (< 150 €):** Clippy EM272 TRS/TRRS (55 €) + Rode AI micro trs/trrs to usb (70 €) + Rycote deadcat (27 €)
- **Best high end system (<400 €):** Clippy EM272 XLR (85 €) or LOM Ucho Pro (75 €) + Focusrite Scarlet 2i2 4th Gen (200 €) + Bubblebee Pro Extreme deadcat (45 €)

**Sources for high end microphones in Europe:**

- Clippy (EM272): <https://www.veldshop.nl/en/clippy-xlr-em272z1-mono-microphone.html>
- LOM (EM272): <https://store.lom.audio/collections/basicucho-series>
- Immersive sound (AOM5024): <https://immersivesoundscapes.com/earsight-standard-v2/>

# App settings recommendation

I've tested lots of settings by running 2 versions of my HA birdnet-pi addon in parallel using the same RTSP feed and comparing the impact of parameters. My conclusions aren't universal, as it seems to be highly dependent on the region and type of mic used. For example, the old model seems to be better in Australia, while the new one is better in Europe.

- **Model**
  - **Version:** 6k_v2.4 _(performs better in Europe at least, the 6k performs better in Australia)_
  - **Species range model:** v1 _(uncheck v2.4; seems more robust in Europe)_
  - **Species occurrence threshold:** 0.001 _(was 0.00015 using v2.4; use the Species List Tester to check the correct value for you)_
- **Audio settings**
  - **Default**
  - **Channel:** 1 _(doesn't really matter as analysis is made on mono signal; 1 allows decreased saved audio size but seems to give slightly messed up spectrograms in my experience)_
  - **Recording Length:** 18 _(that's because I use an overlap of 0.5; so it analyzes 0-3s, 2.5-5.5s, 5-8s, 7.5-10.5, 10-13, 12.5-15.5, 15-18)_
  - **Extraction Length:** 9s _(could be 6, but I like to hear my birds :-))_
  - **Audio format:** mp3 _(why bother with something else)_
- **Birdnet-lite settings**
  - **Overlap:** 0.5s
  - **Minimum confidence:** 0.7
  - **Sigmoid sensitivity:** 1.25 _(I've tried 1.00 but it gave much more false positives; decreasing this value increases sensitivity)_

# Set RTSP server

Inspired by: <https://github.com/mcguirepr89/BirdNET-Pi/discussions/1006#discussioncomment-6747450>

<details>
<summary>On your desktop</summary>

- Download imager
- Install raspbian lite 64

</details>

<details>
<summary>With ssh, install requisite softwares</summary>

```bash
# Update
sudo apt-get update -y
sudo apt-get dist-upgrade -y

# Install RTSP server
sudo apt-get install -y micro ffmpeg lsof
sudo -s cd /root && wget -c https://github.com/bluenviron/mediamtx/releases/download/v1.9.1/mediamtx_v1.9.1_linux_arm64v8.tar.gz -O - | sudo tar -xz
```
</details>

<details>
<summary>Configure Audio</summary>

### Find right device

```bash
# List audio devices
arecord -l

# Check audio device parameters. Example:
arecord -D hw:1,0 --dump-hw-params
```

### Add startup script

```bash
sudo nano startmic.sh && chmod +x startmic.sh
```

Paste the following content:

```bash
#!/bin/bash
echo "Starting birdmic"

# Disable gigabit ethernet
sudo ethtool -s eth0 speed 100 duplex full autoneg on

# Detect Scarlett 2i2 card index - relevant only if you use that card
SCARLETT_INDEX=$(arecord -l | grep -i "Scarlett" | awk '{print $2}' | sed 's/://')

if [ -z "$SCARLETT_INDEX" ]; then
    echo "Error: Scarlett 2i2 not found! Using 0 as default"
    SCARLETT_INDEX="0"
fi

# Start mediamtx first and give it a moment to initialize
./mediamtx &
sleep 5

# Run ffmpeg
ffmpeg -nostdin -use_wallclock_as_timestamps 1 -fflags +genpts -f alsa -acodec pcm_s16be -ac 2 -ar 96000 -i plughw:$SCARLETT_INDEX,0 -ac 2 -f rtsp -acodec pcm_s16be rtsp://localhost:8554/birdmic -rtsp_transport tcp -buffer_size 512k 2>/tmp/rtsp_error &

# Set microphone volume
sleep 5
MICROPHONE_NAME="Line In 1 Gain" # for Focusrite Scarlett 2i2
sudo amixer -c 0 sset "$MICROPHONE_NAME" 40

sleep 60

# Run focusrite and autogain scripts if present
if [ -f "$HOME/focusrite.sh" ]; then
    sudo python3 -u "$HOME/focusrite.sh" >/tmp/log_focusrite 2>/tmp/log_focusrite_error &
fi

if [ -f "$HOME/autogain.py" ]; then
    sudo python3 -u "$HOME/autogain.py" >/tmp/log_autogain 2>/tmp/log_autogain_error &
fi
```
</details>

<details>
<summary>Optional: use gstreamer instead of ffmpeg</summary>

```bash
# Install gstreamer
sudo apt-get update
#sudo apt-get install -y \
#  gstreamer1.0-rtsp \
#  gstreamer1.0-tools \
#  gstreamer1.0-alsa \
#  gstreamer1.0-plugins-base \
#  gstreamer1.0-plugins-good \
#  gstreamer1.0-plugins-bad \
#  gstreamer1.0-plugins-ugly \
#  gstreamer1.0-libav
apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio -y
```

Create a script named `rtsp_audio_server.py`:

```python
#!/usr/bin/env python3

import gi
import sys
import logging
import os
import signal

gi.require_version('Gst', '1.0')
gi.require_version('GstRtspServer', '1.0')

from gi.repository import Gst, GstRtspServer, GLib

# Initialize GStreamer
Gst.init(None)

# Configure Logging
LOG_FILE = "gst_rtsp_server.log"
logging.basicConfig(
    filename=LOG_FILE,
    filemode='a',
    format='%(asctime)s %(levelname)s: %(message)s',
    level=logging.DEBUG  # Set to DEBUG for comprehensive logging
)
logger = logging.getLogger(__name__)

class AudioFactory(GstRtspServer.RTSPMediaFactory):
    def __init__(self):
        super(AudioFactory, self).__init__()
        self.set_shared(True)
        self.set_latency(500)
        self.set_suspend_mode(GstRtspServer.RTSPSuspendMode.NONE)
        logger.debug("AudioFactory initialized: shared=True, latency=500ms, suspend_mode=NONE.")

    def do_create_element(self, url):
        pipeline_str = (
            "alsasrc device=plughw:0,0 do-timestamp=true buffer-time=2000000 latency-time=1000000 ! "
            "queue max-size-buffers=0 max-size-bytes=0 max-size-time=0 ! "
            "audioconvert ! "
            "audioresample ! "
            "audio/x-raw,format=S16BE,channels=2,rate=48000 ! "
            "rtpL16pay name=pay0 pt=96"
        )
        logger.debug(f"Creating GStreamer pipeline: {pipeline_str}")
        try:
            pipeline = Gst.parse_launch(pipeline_str)
            if not pipeline:
                logger.error("Failed to parse GStreamer pipeline.")
                return None
            return pipeline
        except Exception as e:
            logger.error(f"Exception while creating pipeline: {e}")
            return None

class GstServer:
    def __init__(self):
        self.server = GstRtspServer.RTSPServer()
        self.server.set_service("8554")
        self.server.set_address("0.0.0.0")
        logger.debug("RTSP server configured: address=0.0.0.0, port=8554.")

        factory = AudioFactory()
        mount_points = self.server.get_mount_points()
        mount_points.add_factory("/birdmic", factory)
        logger.debug("Factory mounted at /birdmic.")

        self.server.attach(None)
        logger.info("RTSP server attached and running.")

def main():
    server = GstServer()
    print("RTSP server is running at rtsp://localhost:8554/birdmic")
    logger.info("RTSP server is running at rtsp://localhost:8554/birdmic")

    loop = GLib.MainLoop()

    def shutdown(signum, frame):
        logger.info(f"Shutting down RTSP server due to signal {signum}.")
        print("\nShutting down RTSP server.")
        loop.quit()

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    try:
        loop.run()
    except Exception as e:
        logger.error(f"Main loop encountered an exception: {e}")
    finally:
        logger.info("RTSP server has been shut down.")

if __name__ == "__main__":
    if not os.path.exists(LOG_FILE):
        open(LOG_FILE, 'w').close()

    main()
```
</details>

<details>
<summary>Optional: Startup automatically</summary>

```bash
chmod +x startmic.sh
crontab -e # select nano as your editor
```
Paste in:

```bash
@reboot $HOME/startmic.sh
```

then save and exit nano.
Reboot the Pi and test again with VLC to make sure the RTSP stream is live.

</details>

<details>
<summary>Optional: disable unnecessary elements</summary>

- **Optimize config.txt**

```bash
sudo nano /boot/firmware/config.txt
```

Paste in:

```ini
# Enable audio and USB optimizations
dtparam=audio=off          # Disable the default onboard audio to prevent conflicts
dtoverlay=disable-bt        # Disable onboard Bluetooth to reduce USB bandwidth usage
dtoverlay=disable-wifi      # Disable onboard wifi
# Limit Ethernet to 100 Mbps (disable Gigabit Ethernet)
dtparam=eth_max_speed=100
# USB optimizations
dwc_otg.fiq_fix_enable=1    # Enable FIQ (Fast Interrupt) handling for improved USB performance
max_usb_current=1           # Increase the available USB current (required if Scarlett is powered over USB)
# Additional audio settings (for low-latency operation)
avoid_pwm_pll=1             # Use a more stable PLL for the audio clock
# Optional: HDMI and other settings can be turned off if not needed
hdmi_blanking=1             # Disable HDMI (save power and reduce interference)
```

- **Disable useless services**

```bash
# Disable useless services
sudo systemctl disable hciuart
sudo systemctl disable bluetooth
sudo systemctl disable triggerhappy
sudo systemctl disable avahi-daemon
sudo systemctl disable dphys-swapfile
sudo systemctl disable hciuart.service

# Disable bluetooth
for element in bluetooth btbcm hci_uart btintel btrtl btusb; do
    sudo sed -i "/$element/d" /etc/modprobe.d/raspi-blacklist.conf
    echo "blacklist $element" | sudo tee -a /etc/modprobe.d/raspi-blacklist.conf
done

# Disable Video (Including V4L2) on Your Raspberry Pi
for element in bcm2835_v4l2 bcm2835_codec bcm2835_isp videobuf2_vmalloc videobuf2_memops videobuf2_v4l2 videobuf2_common videodev; do
    sudo sed -i "/$element/d" /etc/modprobe.d/raspi-blacklist.conf
    echo "blacklist $element" | sudo tee -a /etc/modprobe.d/raspi-blacklist.conf
done

# Disable WiFi Power Management
sudo iw dev wlan0 set power_save off
for element in brcmfmac brcmutil; do
    sudo sed -i "/$element/d" /etc/modprobe.d/raspi-blacklist.conf
    echo "blacklist $element" | sudo tee -a /etc/modprobe.d/raspi-blacklist.conf
done

# Disable USB Power Management
echo 'on' | sudo tee /sys/bus/usb/devices/usb*/power/control

# Preventing the Raspberry Pi from Entering Power-Saving Mode
sudo apt update
sudo apt install -y cpufrequtils
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
sudo systemctl disable ondemand
sudo systemctl stop ondemand
```
</details>

<details>
<summary>Optional: install Focusrite driver</summary>

```bash
sudo apt-get install make linux-headers-$(uname -r)
curl -LO https://github.com/geoffreybennett/scarlett-gen2/releases/download/v6.9-v1.3/snd-usb-audio-kmod-6.6-v1.3.tar.gz
tar -xzf snd-usb-audio-kmod-6.6-v1.3.tar.gz
cd snd-usb-audio-kmod-6.6-v1.3
KSRCDIR=/lib/modules/$(uname -r)/build
make -j4 -C $KSRCDIR M=$(pwd) clean
make -j4 -C $KSRCDIR M=$(pwd)
sudo make -j4 -C $KSRCDIR M=$(pwd) INSTALL_MOD_DIR=updates/snd-usb-audio modules_install
sudo depmod
sudo reboot
dmesg | grep -A 5 -B 5 -i focusrite
```
</details>

<details>
<summary>Optional: add RAM disk</summary>

```bash
sudo cp /usr/share/systemd/tmp.mount /etc/systemd/system/tmp.mount
sudo systemctl enable tmp.mount
sudo systemctl start tmp.mount
```
</details>

<details>
<summary>Optional: Configuration for Focusrite Scarlett 2i2</summary>

Add this content in `$HOME/focusrite.sh` and run:

```bash
chmod +x "$HOME/focusrite.sh"
```

See: <https://github.com/alexbelgium/Birdnet-tools/blob/main/focusrite.sh>

</details>

<details>
<summary>Optional: Autogain script for microphone</summary>

Add this content in `$HOME/autogain.py` and run:

```bash
chmod +x "$HOME/autogain.py"
```

See: <https://github.com/alexbelgium/Birdnet-tools/blob/main/autogain.py>

</details>
