# Microphone considerations
The critical element is the microphone quality : a Boya By-lm 40 or clippy EM272 (with a very good aux-usb converter) is key to improve the quality of detections. 
Here is some example tests I did (whole threads are really interesting also): https://github.com/mcguirepr89/BirdNET-Pi/discussions/39#discussioncomment-9706951 
https://github.com/mcguirepr89/BirdNET-Pi/discussions/1092#discussioncomment-9706191

My recommendation :
- Best entry system (< 50€) : Boya By-lm40 (30€) + deadcat (10 €)
- Best middle end system (< 150 €) : Clippy EM272 TRS/TRRS (55€) + Rode AI micro trs/trrs to usb (70€) + Rycote deadcat (27€)
- Best high end system (<400 €) : Clippy EM272 XLR (85€) or LOM Ucho Pro (75€) + Focusrite Scarlet 2i2 4th Gen (200€) + Bubblebee Pro Extreme deadcat (45€)

Sources for high end microphones in Europe: 
- Clippy (EM272) : https://www.veldshop.nl/en/clippy-xlr-em272z1-mono-microphone.html
- LOM (EM272) : https://store.lom.audio/collections/basicucho-series
- Immersive sound (AOM5024) : https://immersivesoundscapes.com/earsight-standard-v2/

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
ffmpeg -nostdin -use_wallclock_as_timestamps 1 -fflags +genpts -f alsa -acodec pcm_s16be -ac 2 -ar 96000 \
-i plughw:$SCARLETT_INDEX,0 -ac 2 -f rtsp -acodec pcm_s16be rtsp://localhost:8554/birdmic -rtsp_transport tcp \
-buffer_size 512k 2>/tmp/rtsp_error &

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
Dynamic Microphone Gain Adjustment Script with Interactive Calibration,
Self‑Modification, No‑Signal Reboot Logic, and a Test Mode for Real‑Time RMS Line Graph using plotext

Usage:
  ./autogain.py                 -> Normal dynamic gain control
  ./autogain.py --calibrate     -> Interactive calibration + self-modification
  ./autogain.py --test          -> Test mode (real-time RMS graph)
"""

import argparse
import subprocess
import numpy as np
from scipy.signal import butter, sosfilt
import time
import re
import sys
import os

# ---------------------- Default Configuration ----------------------

MICROPHONE_NAME = "Line In 1 Gain"
MIN_GAIN_DB = 30
MAX_GAIN_DB = 38
GAIN_STEP_DB = 3

# RMS thresholds
NOISE_THRESHOLD_HIGH = 0.01
NOISE_THRESHOLD_LOW  = 0.001

# No-signal detection
NO_SIGNAL_THRESHOLD = 1e-6
NO_SIGNAL_COUNT_THRESHOLD = 3
NO_SIGNAL_ACTION = "scarlett2 reboot && sudo reboot"

SAMPLING_RATE = 48000  # 48 kHz
LOWCUT        = 2000
HIGHCUT       = 8000
FILTER_ORDER  = 4
RTSP_URL      = "rtsp://192.168.178.124:8554/birdmic"
SLEEP_SECONDS = 10

REFERENCE_PRESSURE = 20e-6  # 20 µPa

# Default microphone specifications (for calibration reference)
DEFAULT_SNR         = 80.0    # dB
DEFAULT_SELF_NOISE  = 14.0    # dB-A
DEFAULT_CLIPPING    = 120.0   # dB SPL
DEFAULT_SENSITIVITY = -28.0   # dB re 1 V/Pa

# Compute the default full-scale amplitude (used to derive default fractions)
def_full_scale = (
    REFERENCE_PRESSURE *
    10 ** (DEFAULT_CLIPPING / 20) *
    10 ** (DEFAULT_SENSITIVITY / 20)
)

# ---------------------- Argument Parsing ----------------------

def parse_args():
    parser = argparse.ArgumentParser(
        description="Dynamic Mic Gain Adjustment with calibration, test mode, self‑modification, and reboot logic."
    )
    parser.add_argument("--calibrate", action="store_true", help="Run interactive calibration mode")
    parser.add_argument("--test", action="store_true", help="Run test mode to display a real‑time RMS graph using plotext")
    return parser.parse_args()

# ---------------------- Audio & Gain Helpers ----------------------

def debug_print(msg, level="info"):
    current_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    print(f"[{current_time}] [{level.upper()}] {msg}")

def get_gain_db(mic_name):
    try:
        output = subprocess.check_output(
            ['amixer', 'sget', mic_name], stderr=subprocess.STDOUT
        ).decode()
        match = re.search(r'\[(-?\d+(\.\d+)?)dB\]', output)
        if match:
            return float(match.group(1))
    except subprocess.CalledProcessError as e:
        debug_print(f"amixer sget failed: {e}", "error")
    return None

def set_gain_db(mic_name, gain_db):
    gain_db = max(min(gain_db, MAX_GAIN_DB), MIN_GAIN_DB)
    try:
        subprocess.check_call(
            ['amixer', 'sset', mic_name, f'{int(gain_db)}dB'],
            stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT
        )
        debug_print(f"Gain set to: {gain_db} dB", "info")
        return True
    except subprocess.CalledProcessError as e:
        debug_print(f"Failed to set gain: {e}", "error")
    return False

def capture_audio(rtsp_url, duration=5):
    cmd = [
        'ffmpeg', '-loglevel', 'error', '-rtsp_transport', 'tcp',
        '-i', rtsp_url, '-vn', '-f', 's16le', '-acodec', 'pcm_s16le',
        '-ar', str(SAMPLING_RATE), '-ac', '1', '-t', str(duration), '-'
    ]
    try:
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = process.communicate()
        if process.returncode != 0:
            debug_print(f"ffmpeg failed: {stderr.decode().strip()}", "error")
            return None
        return np.frombuffer(stdout, dtype=np.int16).astype(np.float32) / 32768.0
    except Exception as e:
        debug_print(f"Audio capture exception: {e}", "error")
        return None

def bandpass_filter(audio, lowcut, highcut, fs, order=4):
    sos = butter(order, [lowcut, highcut], btype='band', fs=fs, output='sos')
    return sosfilt(sos, audio)

def measure_rms(audio):
    return float(np.sqrt(np.mean(audio**2))) if len(audio) > 0 else 0.0

# ---------------------- Interactive Calibration ----------------------

def prompt_float(prompt_str, default_val):
    while True:
        user_input = input(f"{prompt_str} [{default_val}]: ").strip()
        if user_input == "":
            return default_val
        try:
            return float(user_input)
        except ValueError:
            print("Invalid input; please enter a numeric value.")

def interactive_calibration():
    print("\n-- INTERACTIVE CALIBRATION --")
    print("Enter the microphone characteristics (press Enter to accept default):\n")
    snr = prompt_float("1) Signal-to-Noise Ratio (dB)", DEFAULT_SNR)
    self_noise = prompt_float("2) Self Noise (dB-A)", DEFAULT_SELF_NOISE)
    clipping = prompt_float("3) Clipping SPL (dB)", DEFAULT_CLIPPING)
    sensitivity = prompt_float("4) Sensitivity (dB re 1 V/Pa)", DEFAULT_SENSITIVITY)
    return {"snr": snr, "self_noise": self_noise, "clipping": clipping, "sensitivity": sensitivity}

def calibrate_and_propose(mic_params):
    user_snr = mic_params["snr"]
    clipping = mic_params["clipping"]
    sensitivity = mic_params["sensitivity"]

    user_full_scale = (
        REFERENCE_PRESSURE *
        10 ** (clipping / 20) *
        10 ** (sensitivity / 20)
    )
    fraction_high_default = NOISE_THRESHOLD_HIGH / def_full_scale
    fraction_low_default  = NOISE_THRESHOLD_LOW  / def_full_scale
    snr_ratio = user_snr / DEFAULT_SNR

    proposed_high = fraction_high_default * user_full_scale * snr_ratio
    proposed_low  = fraction_low_default  * user_full_scale * snr_ratio
    gain_offset = (DEFAULT_SENSITIVITY - sensitivity)
    proposed_min_gain = MIN_GAIN_DB + gain_offset
    proposed_max_gain = MAX_GAIN_DB + gain_offset

    print("\n===============================================================")
    print("CURRENT VALUES:")
    print("---------------------------------------------------------------")
    print(f"  NOISE_THRESHOLD_HIGH: {NOISE_THRESHOLD_HIGH:.7f}")
    print(f"  NOISE_THRESHOLD_LOW:  {NOISE_THRESHOLD_LOW:.7f}")
    print(f"  MIN_GAIN_DB:          {MIN_GAIN_DB}")
    print(f"  MAX_GAIN_DB:          {MAX_GAIN_DB}")
    print("---------------------------------------------------------------\n")
    print("PROPOSED VALUES:")
    print("---------------------------------------------------------------")
    print(f"  Proposed NOISE_THRESHOLD_HIGH: {proposed_high:.7f}")
    print(f"  Proposed NOISE_THRESHOLD_LOW:  {proposed_low:.7f}\n")
    print("  Proposed Gain Range (dB):")
    print(f"    MIN_GAIN_DB: {proposed_min_gain:.2f}")
    print(f"    MAX_GAIN_DB: {proposed_max_gain:.2f}")
    print("---------------------------------------------------------------\n")

    return {
        "noise_threshold_high": proposed_high,
        "noise_threshold_low": proposed_low,
        "min_gain_db": proposed_min_gain,
        "max_gain_db": proposed_max_gain,
    }

def persist_calibration_to_script(script_path, proposal):
    subs = {
        "NOISE_THRESHOLD_HIGH": f"{proposal['noise_threshold_high']:.7f}",
        "NOISE_THRESHOLD_LOW":  f"{proposal['noise_threshold_low']:.7f}",
        "MIN_GAIN_DB":          f"{int(round(proposal['min_gain_db']))}",
        "MAX_GAIN_DB":          f"{int(round(proposal['max_gain_db']))}"
    }
    for var, val in subs.items():
        cmd = f"sed -i 's|^{var} = .*|{var} = {val}|' \"{script_path}\""
        os.system(cmd)
    print("✅ Script has been updated with the new calibration values.\n")

# ---------------------- Test Mode: Real-Time RMS Graph using plotext ----------------------

def test_mode():
    try:
        import plotext as plt
    except ImportError:
        print("plotext is required for test mode. Please install it using 'pip install plotext'.")
        sys.exit(1)

    print("\n-- TEST MODE: Real-Time RMS Line Graph (plotext) --")
    print("Recording 5-second samples in a loop. Press Ctrl+C to exit.\n")
    rms_history = []
    iterations = []
    max_points = 20
    i = 0

    while True:
        audio = capture_audio(RTSP_URL, duration=5)
        if audio is None or len(audio) == 0:
            print("No audio captured, retrying...")
            time.sleep(5)
            continue

        filtered = bandpass_filter(audio, LOWCUT, HIGHCUT, SAMPLING_RATE, FILTER_ORDER)
        rms = measure_rms(filtered)

        rms_history.append(rms)
        iterations.append(i)
        i += 1

        if len(rms_history) > max_points:
            rms_history = rms_history[-max_points:]
            iterations = iterations[-max_points:]

        if rms > NOISE_THRESHOLD_HIGH:
            status = "🔴 ABOVE"
        elif rms < NOISE_THRESHOLD_LOW:
            status = "🔵 BELOW"
        else:
            status = "🟢 OK"

        plt.clf()
        plt.plot(iterations, rms_history, marker="dot", color="cyan")
        plt.horizontal_line(NOISE_THRESHOLD_HIGH, color="red")
        plt.horizontal_line(NOISE_THRESHOLD_LOW, color="blue")
        plt.title("Real-Time RMS (Line Graph)")
        plt.xlabel("Iteration")
        plt.ylabel("RMS")
        plt.ylim(0, max(0.001, max(rms_history) * 1.2))
        plt.show()

        print(f"Current RMS: {rms:.6f} — {status}")
        time.sleep(0.5)

# ---------------------- Dynamic Gain Control Loop ----------------------

def dynamic_gain_control():
    debug_print("Starting dynamic gain controller...", "info")
    set_gain_db(MICROPHONE_NAME, (MIN_GAIN_DB + MAX_GAIN_DB) // 2)

    no_signal_count = 0

    while True:
        audio = capture_audio(RTSP_URL)
        if audio is None or len(audio) == 0:
            debug_print("No audio captured; retrying...", "warning")
            time.sleep(SLEEP_SECONDS)
            continue

        filtered = bandpass_filter(audio, LOWCUT, HIGHCUT, SAMPLING_RATE, FILTER_ORDER)
        rms = measure_rms(filtered)
        debug_print(f"Measured RMS: {rms:.6f}", "info")

        # No-signal detection
        if rms < NO_SIGNAL_THRESHOLD:
            no_signal_count += 1
            debug_print(f"No signal detected ({no_signal_count}/{NO_SIGNAL_COUNT_THRESHOLD})", "warning")
            if no_signal_count >= NO_SIGNAL_COUNT_THRESHOLD:
                debug_print("No signal for too long, executing action...", "error")
                subprocess.call(NO_SIGNAL_ACTION, shell=True)
        else:
            no_signal_count = 0

        current_gain = get_gain_db(MICROPHONE_NAME)
        if current_gain is None:
            debug_print("Failed to read current gain; skipping cycle.", "warning")
            time.sleep(SLEEP_SECONDS)
            continue

        if rms > NOISE_THRESHOLD_HIGH:
            set_gain_db(MICROPHONE_NAME, current_gain - GAIN_STEP_DB)
        elif rms < NOISE_THRESHOLD_LOW:
            set_gain_db(MICROPHONE_NAME, current_gain + GAIN_STEP_DB)

        time.sleep(SLEEP_SECONDS)

# ---------------------- Main ----------------------

def main():
    args = parse_args()

    if args.calibrate:
        mic_params = interactive_calibration()
        proposal = calibrate_and_propose(mic_params)
        save = input("Save these values permanently into the script? [y/N]: ").strip().lower()
        if save in ["y", "yes"]:
            persist_calibration_to_script(os.path.abspath(__file__), proposal)
            print("👍 Calibration values saved. Exiting now.\n")
        else:
            print("❌ Not saving values. Exiting.\n")
        sys.exit(0)

    if args.test:
        test_mode()
        sys.exit(0)

    dynamic_gain_control()

if __name__ == "__main__":
    main()

```

</details>
