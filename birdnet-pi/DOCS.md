# Microphone considerations
The critical element is the microphone quality : a Boya By-lm 40 or clippy EM272 (with a very good aux-usb converter) is key to improve the quality of detections. 
Here is some example tests I did (whole threads are really interesting also): https://github.com/mcguirepr89/BirdNET-Pi/discussions/39#discussioncomment-9706951 
https://github.com/mcguirepr89/BirdNET-Pi/discussions/1092#discussioncomment-9706191

My recommendation :
- Best entry system (< 50€) : Boya By-lm40 (30€) + deadcat (10 €)
- Best middle end system (< 150 €) : Clippy EM272 TRS/TRRS (55€) + Rode AI micro trs/trrs to usb (70€) + Rycote deadcat (27€)
- Best high end system (<400 €) : Clippy EM272 XLR (85€) or LOM Ucho Pro (75€) + Focusrite Scarlet 2i2 4th Gen (200€) + Bubblebee Pro Extreme deadcat (45€)

# App settings recommendation
I've tested lots of settings by running 2 versions of my HA birdnet-pi addon in parallel using the same rtsp feed, and comparing impact of parameters. 
My conclusions aren't universal, as it seems to be highly dependent on the region and type of mic used. For example, the old model seems to be better in Australia, while the new one better in Europe.

- Model
    - Version : 6k_v2,4 _(performs better in Europe at least, the 6k performs better in Australia)_
    - Species range model : v1 _(uncheck v2.4 ; seems more robust in Europe)_
    - Species occurence threshold : 0,001 _(was 0,00015 using v2.4 ; use the Species List Tester to check the correct value for you)_
- Audio settings
    - Default
    - Channel : 1 _(doesn't really matter as analysis is made on mono signal ; 1 allows decreased saved audio size but seems to give slightly messed up spectrograms in my experience)_
    - Recording Length : 18 _(that's because I use an overlap of 0,5 ; so it analysis 0-3s ; 2,5-5,5s ; 5-8s ; 7,5-10,5 ; 10-13 ; 12,5-15,5 ; 15-18)_
    - Extraction Length : 9s _(could be 6, but I like to hear my birds :-))_
    - Audio format : mp3 _(why bother with something else)_
- Birdnet-lite settings
    - Overlap : 0,5s
    - Minimum confidence : 0,7
    - Sigmoid sensitivity : 1,25 _(I've tried 1,00 but it gave much more false positives ; as decreasing this value increases sensitivity)_

# Set RTSP server

Inspired by : https://github.com/mcguirepr89/BirdNET-Pi/discussions/1006#discussioncomment-6747450

<details>
<summary>On your desktop</summary>
   
- Download imager
- Install raspbian lite 64
</details>

<details>
<summary>With ssh, install requisite softwares</summary>

### 
```
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
```
# List audio devices
arecord -l

# Check audio device parameters. Example :
arecord -D hw:1,0 --dump-hw-params
```

### Add startup script
sudo nano startmic.sh && chmod +x startmic.sh
```
#!/bin/bash
echo "Starting birdmic"

# Disable gigabit ethernet
sudo ethtool -s eth0 speed 100 duplex full autoneg on

# Start mediamtx first and give it a moment to initialize
./mediamtx & 
sleep 5
    
# Run ffmpeg
ffmpeg -nostdin -use_wallclock_as_timestamps 1 -fflags +genpts -f alsa -acodec pcm_s16be -ac 2 -ar 96000 \
-i plughw:0,0 -ac 2 -f rtsp -acodec pcm_s16be rtsp://localhost:8554/birdmic -rtsp_transport tcp \
-buffer_size 512k 2>/tmp/rtsp_error &

# Set microphone volume
sleep 5
MICROPHONE_NAME="Line In 1 Gain" # for Focusrite Scarlett 2i2
sudo amixer -c 0 sset "$MICROPHONE_NAME" 40

sleep 60

# Run focusrite and autogain scripts if present
if [ -f "$HOME/focusrite.sh" ]; then
    "$HOME/focusrite.sh" >/tmp/log_focusrite 2>/tmp/log_focusrite_error &
fi

if [ -f "$HOME/autogain.py" ]; then
    "$HOME/autogain.py" >/tmp/log_autogain 2>/tmp/log_autogain_error &
fi
```

</details>

<details>
<summary>Optional : use gstreamer instead of ffmpeg</summary>

```
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

Create a script named rtsp_audio_server.py
```
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
        self.set_shared(True)          # Allow multiple clients to access the stream
        self.set_latency(500)          # Increase latency to 500ms to improve stream stability
        self.set_suspend_mode(GstRtspServer.RTSPSuspendMode.NONE)  # Prevent suspension of the stream when no clients are connected
        logger.debug("AudioFactory initialized: shared=True, latency=500ms, suspend_mode=NONE.")

    def do_create_element(self, url):
        """
        Create and return the GStreamer pipeline for streaming audio.
        """
        pipeline_str = (
            "alsasrc device=plughw:0,0 do-timestamp=true buffer-time=2000000 latency-time=1000000 ! "  # Increased buffer size
            "queue max-size-buffers=0 max-size-bytes=0 max-size-time=0 ! "         # Add queue to handle buffer management
            "audioconvert ! "                                # Convert audio to a suitable format
            "audioresample ! "                               # Resample audio if necessary
            "audio/x-raw,format=S16BE,channels=2,rate=48000 ! "  # Set audio properties (rate = 48kHz)
            "rtpL16pay name=pay0 pt=96"                     # Payload for RTP
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
        self.server.set_service("8554")      # Set the RTSP server port
        self.server.set_address("0.0.0.0")   # Listen on all network interfaces
        logger.debug("RTSP server configured: address=0.0.0.0, port=8554.")

        factory = AudioFactory()
        mount_points = self.server.get_mount_points()
        mount_points.add_factory("/birdmic", factory)  # Mount point
        logger.debug("Factory mounted at /birdmic.")

        self.server.attach(None)  # Attach the server to the default main context
        logger.info("RTSP server attached and running.")

def main():
    # Create GstServer instance
    server = GstServer()
    print("RTSP server is running at rtsp://localhost:8554/birdmic")
    logger.info("RTSP server is running at rtsp://localhost:8554/birdmic")

    # Set up the main loop with proper logging
    loop = GLib.MainLoop()

    # Handle termination signals to ensure graceful shutdown
    def shutdown(signum, frame):
        logger.info(f"Shutting down RTSP server due to signal {signum}.")
        print("\nShutting down RTSP server.")
        loop.quit()

    # Register signal handlers for graceful termination
    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    try:
        loop.run()
    except Exception as e:
        logger.error(f"Main loop encountered an exception: {e}")
    finally:
        logger.info("RTSP server has been shut down.")

if __name__ == "__main__":
    # Ensure log file exists
    if not os.path.exists(LOG_FILE):
        open(LOG_FILE, 'w').close()

    main()
```

</details>

<details>
<summary>Optional : Startup automatically</summary>

```
chmod +x startmic.sh
crontab -e # select nano as your editor
```
Paste in `@reboot $HOME/startmic.sh` then save and exit nano.
Reboot the Pi and test again with VLC to make sure the RTSP stream is live.

</details>

<details>
<summary>Optional : disable unecessary elements</summary>

- Optimize config.txt

sudo nano /boot/firmware/config.txt
```
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

- Disable useless services

```

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
<summary>Optional : install Focusrite driver</summary>
    
```
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
<summary>Optional : add RAM disk</summary>
    
```
sudo cp /usr/share/systemd/tmp.mount /etc/systemd/system/tmp.mount
sudo systemctl enable tmp.mount
sudo systemctl start tmp.mount
```

</details>

<details>
<summary>Optional : Configuration for Focusrite Scarlett 2i2</summary>

Add this content in "$HOME/focusrite.sh" && chmod +x "$HOME/focusrite.sh"
```
#!/bin/bash

# Set PCM controls for capture
sudo amixer -c 0 cset numid=31 'Analogue 1'  # 'PCM 01' - Set to 'Analogue 1'
sudo amixer -c 0 cset numid=32 'Analogue 1'  # 'PCM 02' - Set to 'Analogue 1'
sudo amixer -c 0 cset numid=33 'Off'         # 'PCM 03' - Disabled
sudo amixer -c 0 cset numid=34 'Off'         # 'PCM 04' - Disabled

# Set DSP Input controls (Unused, set to Off)
sudo amixer -c 0 cset numid=29 'Off'         # 'DSP Input 1'
sudo amixer -c 0 cset numid=30 'Off'         # 'DSP Input 2'

# Configure Line In 1 as main input for mono setup
sudo amixer -c 0 cset numid=8 'Off'          # 'Line In 1 Air' - Keep 'Off'
sudo amixer -c 0 cset numid=14 off           # 'Line In 1 Autogain' - Disabled
sudo amixer -c 0 cset numid=6 'Line'         # 'Line In 1 Level' - Set level to 'Line'
sudo amixer -c 0 cset numid=21 on           # 'Line In 1 Safe' - Enabled to avoid clipping / noise impact ?

# Disable Line In 2 to minimize interference (if not used)
sudo amixer -c 0 cset numid=9 'Off'          # 'Line In 2 Air'
sudo amixer -c 0 cset numid=17 off           # 'Line In 2 Autogain' - Disabled
sudo amixer -c 0 cset numid=16 0             # 'Line In 2 Gain' - Set gain to 0 (mute)
sudo amixer -c 0 cset numid=7 'Line'         # 'Line In 2 Level' - Set to 'Line'
sudo amixer -c 0 cset numid=22 off           # 'Line In 2 Safe' - Disabled

# Set Line In 1-2 controls
sudo amixer -c 0 cset numid=12 off           # 'Line In 1-2 Link' - No need to link for mono
sudo amixer -c 0 cset numid=10 on            # 'Line In 1-2 Phantom Power' - Enabled for condenser mics

# Set Analogue Outputs to use the same mix for both channels (Mono setup)
sudo amixer -c 0 cset numid=23 'Mix A'       # 'Analogue Output 01' - Set to 'Mix A'
sudo amixer -c 0 cset numid=24 'Mix A'       # 'Analogue Output 02' - Same mix as Output 01

# Set Direct Monitor to off to prevent feedback
sudo amixer -c 0 cset numid=53 'Off'         # 'Direct Monitor'

# Set Input Select to Input 1
sudo amixer -c 0 cset numid=11 'Input 1'     # 'Input Select'

# Optimize Monitor Mix settings for mono output
sudo amixer -c 0 cset numid=54 153           # 'Monitor 1 Mix A Input 01' - Set to 153 (around -3.50 dB)
sudo amixer -c 0 cset numid=55 153           # 'Monitor 1 Mix A Input 02' - Set to 153 for balanced output
sudo amixer -c 0 cset numid=56 0             # 'Monitor 1 Mix A Input 03' - Mute unused channels
sudo amixer -c 0 cset numid=57 0             # 'Monitor 1 Mix A Input 04'

# Set Sync Status to Locked
sudo amixer -c 0 cset numid=52 'Locked'      # 'Sync Status'

echo "Mono optimization applied. Only using primary input and balanced outputs."
```
</details>

<details>
<summary>Optional : Autogain script for microphone</summary>

Add this content in "$HOME/autogain.py" && chmod +x "$HOME/autogain.py"

```python
#!/usr/bin/env python3
"""
Microphone Gain Adjustment Script with THD and Overload Detection

This script captures audio from an RTSP stream, processes it to calculate the RMS
within the 2000-8000 Hz frequency band, detects clipping, calculates Total Harmonic
Distortion (THD) over the full frequency range, and adjusts the microphone gain based 
on predefined noise thresholds, trends, and distortion metrics.

Dependencies:
- numpy
- scipy
- ffmpeg (installed and accessible in PATH)
- amixer (for microphone gain control)

Changelog:
- 2024-10-27: Increased sampling rate to 48,000 Hz.
- 2024-10-27: Extended THD calculation over the full frequency range.
- 2024-10-27: Added gain stabilization delay to reduce frequent adjustments.
- 2024-10-27: Improved RTSP stream resilience with retry logic.
- 2024-10-27: Enhanced debug output with logging levels.
- 2024-10-28: Added summary log mode for simplified output.
- 2024-10-28: Removed gain stabilization delay for immediate gain adjustments.
- 2024-10-28: Implemented sampling rate reduction, capture duration reduction, scipy.fft usage, lower filter order, and multiprocessing for efficiency.
- 2024-10-31: Max gain capped at 40 dB, suppressed `amixer` logging.
"""

import subprocess
import numpy as np
from scipy.signal import butter, sosfilt, find_peaks
from scipy.fft import rfft, rfftfreq
import time
import re
import multiprocessing as mp
import sys

# ---------------------------- Configuration ----------------------------

# Microphone Settings
MICROPHONE_NAME = "Line In 1 Gain"
MIN_GAIN_DB = 20
MAX_GAIN_DB = 40  # Capped at 40 dB
DECREASE_GAIN_STEP_DB = 1
INCREASE_GAIN_STEP_DB = 5
CLIPPING_REDUCTION_DB = 3

# Noise Thresholds
NOISE_THRESHOLD_HIGH = 0.001
NOISE_THRESHOLD_LOW = 0.00035

# Trend Detection
TREND_COUNT_THRESHOLD = 3

# Sampling Rate
SAMPLING_RATE = 44100  # Reduced from 48000 Hz to 44100 Hz

# Audio Capture Duration
AUDIO_CAPTURE_DURATION = 2  # Reduced from 5 seconds to 2 seconds

# RTSP Stream URL
RTSP_URL = "rtsp://192.168.178.124:8554/birdmic"

# Debug and Summary Modes
DEBUG = 1            # Debug Mode (1 for enabled, 0 for disabled)
SUMMARY_MODE = True  # Summary Mode (True for summary output only)

# Microphone Characteristics
MIC_SENSITIVITY_DB = -28
MIC_CLIPPING_SPL = 120

# Calibration Constants
REFERENCE_PRESSURE = 20e-6

# THD Settings
THD_FUNDAMENTAL_THRESHOLD_DB = 60
MAX_THD_PERCENTAGE = 5.0

# Filter Settings
LOWCUT = 2000
HIGHCUT = 8000
FILTER_ORDER = 3  # Reduced from 5 to 3 for efficiency

# -----------------------------------------------------------------------

def debug_print(msg, level="info"):
    """
    Prints debug messages with logging levels if DEBUG mode is enabled.
    """
    if DEBUG and not SUMMARY_MODE:
        current_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        print(f"[{current_time}] [{level.upper()}] {msg}")

def summary_log(current_gain, clipping, rms_amplitude, thd_percentage):
    """
    Outputs a summary log with date, time, current gain, clipping status, background noise, and THD.
    """
    if SUMMARY_MODE:
        current_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        clipping_status = "Yes" if clipping else "No"
        print(f"{current_time} | Gain: {current_gain:.1f} dB | Clipping: {clipping_status} | "
              f"Noise: {rms_amplitude:.5f} | THD: {thd_percentage:.2f}%")

def get_gain_db(mic_name):
    """
    Retrieves the current gain setting of the specified microphone using amixer.
    Considers only the integer part of the gain.
    """
    cmd = ['amixer', 'sget', mic_name]
    try:
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT).decode()
        match = re.search(r'\[(-?\d+)', output)  # Match only integer part
        if match:
            return int(match.group(1))
        else:
            return None
    except subprocess.CalledProcessError:
        return None

def set_gain_db(mic_name, gain_db):
    """
    Sets the gain of the specified microphone using amixer.
    Suppresses output by redirecting to /dev/null.
    """
    if gain_db > MAX_GAIN_DB:
        return False  # Do not exceed max gain

    cmd = ['amixer', 'sset', mic_name, f'{gain_db}dB']
    try:
        subprocess.check_call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def main():
    # Example usage
    current_gain_db = get_gain_db(MICROPHONE_NAME)
    if current_gain_db is not None:
        if current_gain_db < MAX_GAIN_DB:
            new_gain_db = min(current_gain_db + INCREASE_GAIN_STEP_DB, MAX_GAIN_DB)
            if set_gain_db(MICROPHONE_NAME, new_gain_db):
                print(f"Gain increased to {new_gain_db} dB")
        else:
            print("Gain is already at maximum and will not be increased.")
    else:
        print("Failed to retrieve current gain level.")

if __name__ == "__main__":
    main()
```

</details>
