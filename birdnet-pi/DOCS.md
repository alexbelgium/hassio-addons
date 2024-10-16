# Microphone considerations
The critical element is the microphone quality : a Boya By-lm 40 or clippy EM272 (with a very good aux-usb converter) is key to improve the quality of detections. 
Here is some example tests I did (whole threads are really interesting also): https://github.com/mcguirepr89/BirdNET-Pi/discussions/39#discussioncomment-9706951 
https://github.com/mcguirepr89/BirdNET-Pi/discussions/1092#discussioncomment-9706191

My recommendation :
- Best entry system (< 50€) : Boya By-lm40 (30€) + deadcat (10 €)
- Best middle end system (< 150 €) : Clippy EM272 (55€) + Rode AI micro trrs to usb (70€) + Rycote deadcat (27€)
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

# Set RTSP server (https://github.com/mcguirepr89/BirdNET-Pi/discussions/1006#discussioncomment-6747450)

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

# Disable useless services
sudo systemctl disable hciuart
sudo systemctl disable bluetooth
sudo systemctl disable triggerhappy
sudo systemctl disable avahi-daemon
sudo systemctl disable dphys-swapfile

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
#!/bin/bash
echo "Starting birdmic"
# Disable gigabit ethernet
sudo ethtool -s eth0 speed 100 duplex full autoneg on
# Start rtsp server
./mediamtx & true
# Create rtsp feed
sleep 5

# Using ffmpeg
ffmpeg -nostdin -use_wallclock_as_timestamps 1 -fflags +genpts -f alsa -acodec pcm_s16be -ac 2 -ar 48000 -i plughw:0,0 -ac 2 -f rtsp -acodec pcm_s16be rtsp://localhost:8554/birdmic -rtsp_transport tcp -buffer_size 512k 2> /tmp/log_rtsp || true & true
#ffmpeg -nostdin -f alsa -acodec pcm_s16be -ac 2 -ar 48000 -i hw:0,0 -f rtsp -acodec pcm_s16be rtsp://localhost:8554/birdmic -rtsp_transport tcp -buffer_size 512k 2> /tmp/log_rtsp || true & true

# Using GStreamer pipeline, uncomment to use
#gst-launch-1.0 -v \
#  alsasrc device=hw:0,0 ! \
#  audio/x-raw,format=S16LE,channels=2,rate=48000 ! \
#  audioconvert ! \
#  audioresample ! \
#  rtpL16pay ! \
#  rtspclientsink location=rtsp://localhost:8554/birdmic protocols=tcp \
#  2> /tmp/log_rtsp || true &

# Set microphone volume
sleep 5
MICROPHONE_NAME="Line In 1 Gain" # for Focusrite Scarlett 2i2
sudo amixer -c 0 sset "$MICROPHONE_NAME" 40

sleep 60

if [ -f "$HOME/focusrite.sh" ]; then
    touch /tmp/log /tmp/log_error
    "$HOME/focusrite.sh" >/tmp/log_focusrite 2>/tmp/log_focusrite_error & true
fi

if [ -f "$HOME/autogain.py" ]; then
    touch /tmp/log /tmp/log_error
    python autogain.py >/tmp/log_autogain 2>/tmp/log_autogain_error & true
fi

```

</details>

<details>
<summary>Optional : use gstreamer instead of ffmpeg</summary>

```
# Install gstreamer
sudo apt-get update
sudo apt-get install -y \
  gstreamer1.0-rtsp \
  gstreamer1.0-tools \
  gstreamer1.0-alsa \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-libav
```

Remove the ffmpeg line in your startmic.sh and use instead

</details>

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
<summary>Optional : optimize config.txt</summary>

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
Microphone Gain Adjustment Script

This script captures audio from an RTSP stream, processes it to calculate the RMS
within the 2000-4000 Hz frequency band, and adjusts the microphone gain based on
predefined noise thresholds and trends.

Dependencies:
- numpy
- scipy
- ffmpeg (installed and accessible in PATH)
- amixer (for microphone gain control)

Author: OpenAI ChatGPT
Date: 2024-04-27
"""

import subprocess
import numpy as np
from scipy.signal import butter, sosfilt
import time
import re

# ---------------------------- Configuration ----------------------------

# Microphone Settings
MICROPHONE_NAME = "Line In 1 Gain"  # Adjust to match your microphone's control name
MIN_GAIN_DB = 20                    # Minimum gain in dB
MAX_GAIN_DB = 45                    # Maximum gain in dB
DECREASE_GAIN_STEP_DB = 1           # Gain decrease step in dB
INCREASE_GAIN_STEP_DB = 5           # Gain increase step in dB

# Noise Thresholds
NOISE_THRESHOLD_HIGH = 0.001         # Upper threshold for noise RMS amplitude
NOISE_THRESHOLD_LOW = 0.00035         # Lower threshold for noise RMS amplitude

# Trend Detection
TREND_COUNT_THRESHOLD = 1           # Number of consecutive trends needed to adjust gain

# RTSP Stream URL
RTSP_URL = "rtsp://192.168.178.124:8554/birdmic"  # Replace with your RTSP stream URL

# Debug Mode (1 for enabled, 0 for disabled)
DEBUG = 1

# -----------------------------------------------------------------------


def debug(msg):
    """
    Prints debug messages if DEBUG mode is enabled.

    :param msg: The debug message to print.
    """
    if DEBUG:
        print(f"[DEBUG] {msg}")


def get_gain_db(mic_name):
    """
    Retrieves the current gain setting of the specified microphone using amixer.

    :param mic_name: The name of the microphone control in amixer.
    :return: The current gain in dB as a float, or None if retrieval fails.
    """
    cmd = ['amixer', 'sget', mic_name]
    try:
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT).decode()
        # Regex to find patterns like [30.00dB]
        match = re.search(r'\[(-?\d+(\.\d+)?)dB\]', output)
        if match:
            gain_db = float(match.group(1))
            debug(f"Retrieved gain: {gain_db} dB")
            return gain_db
        else:
            debug("No gain information found in amixer output.")
            return None
    except subprocess.CalledProcessError as e:
        debug(f"amixer sget failed: {e}")
        return None


def set_gain_db(mic_name, gain_db):
    """
    Sets the gain of the specified microphone using amixer.

    :param mic_name: The name of the microphone control in amixer.
    :param gain_db: The desired gain in dB.
    :return: True if the gain was set successfully, False otherwise.
    """
    cmd = ['amixer', 'sset', mic_name, f'{gain_db}dB']
    try:
        subprocess.check_call(cmd, stderr=subprocess.STDOUT)
        debug(f"Set gain to: {gain_db} dB")
        return True
    except subprocess.CalledProcessError as e:
        debug(f"amixer sset failed: {e}")
        return False


def calculate_noise_rms(rtsp_url, bandpass_sos, num_bins=5):
    """
    Captures audio from an RTSP stream, applies a bandpass filter, divides the
    audio into segments, and calculates the RMS of the quietest segment.

    :param rtsp_url: The RTSP stream URL.
    :param bandpass_sos: Precomputed bandpass filter coefficients (Second-Order Sections).
    :param num_bins: Number of segments to divide the audio into.
    :return: The RMS amplitude of the quietest segment as a float, or None on failure.
    """
    cmd = [
        'ffmpeg',
        '-loglevel', 'error',
        '-rtsp_transport', 'tcp',
        '-i', rtsp_url,
        '-vn',
        '-f', 's16le',
        '-acodec', 'pcm_s16le',
        '-ar', '32000',
        '-ac', '1',
        '-t', '5',
        '-'
    ]

    try:
        debug(f"Starting audio capture from {rtsp_url}")
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = process.communicate()

        if process.returncode != 0:
            debug(f"ffmpeg failed with error: {stderr.decode()}")
            return None

        # Convert raw PCM data to numpy array
        audio = np.frombuffer(stdout, dtype=np.int16).astype(np.float32) / 32768.0
        debug(f"Captured {len(audio)} samples from audio stream.")

        if len(audio) == 0:
            debug("No audio data captured.")
            return None

        # Apply bandpass filter
        filtered = sosfilt(bandpass_sos, audio)
        debug("Applied bandpass filter to audio data.")

        # Divide into num_bins
        total_samples = len(filtered)
        bin_size = total_samples // num_bins

        if bin_size == 0:
            debug("Bin size is 0; insufficient audio data.")
            return 0.0

        trimmed_length = bin_size * num_bins
        trimmed_filtered = filtered[:trimmed_length]
        segments = trimmed_filtered.reshape(num_bins, bin_size)
        debug(f"Divided audio into {num_bins} bins of {bin_size} samples each.")

        # Calculate RMS for each segment
        rms_values = np.sqrt(np.mean(segments ** 2, axis=1))
        debug(f"Calculated RMS values for each segment: {rms_values}")

        # Return the minimum RMS value
        min_rms = rms_values.min()
        debug(f"Minimum RMS value among segments: {min_rms}")

        return min_rms

    except Exception as e:
        debug(f"Exception during noise RMS calculation: {e}")
        return None


def main():
    """
    Main loop that continuously monitors background noise and adjusts microphone gain.
    """
    TREND_COUNT = 0
    PREVIOUS_TREND = 0

    # Precompute the bandpass filter coefficients
    LOWCUT = 2000    # Lower frequency bound in Hz
    HIGHCUT = 8000   # Upper frequency bound in Hz
    FILTER_ORDER = 5 # Order of the Butterworth filter

    sos = butter(FILTER_ORDER, [LOWCUT, HIGHCUT], btype='band', fs=44100, output='sos')
    debug("Precomputed Butterworth bandpass filter coefficients.")

    # Set the microphone gain to the maximum gain at the start
    success = set_gain_db(MICROPHONE_NAME, MAX_GAIN_DB)
    if success:
        print(f"Microphone gain set to {MAX_GAIN_DB} dB at start.")
    else:
        print("Failed to set microphone gain at start. Exiting.")
        return

    while True:
        min_rms = calculate_noise_rms(RTSP_URL, sos, num_bins=5)

        if min_rms is None:
            print("Failed to compute noise RMS. Retrying in 1 minute...")
            time.sleep(60)
            continue

        if not isinstance(min_rms, (float, int)):
            print(f"Invalid noise RMS output detected: {min_rms}. Retrying in 1 minute...")
            time.sleep(60)
            continue

        # Print the final converted RMS amplitude (only once)
        print(f"Converted RMS Amplitude: {min_rms}")
        debug(f"Current background noise (RMS amplitude): {min_rms}")

        # Determine the noise trend
        if min_rms > NOISE_THRESHOLD_HIGH:
            CURRENT_TREND = 1
        elif min_rms < NOISE_THRESHOLD_LOW:
            CURRENT_TREND = -1
        else:
            CURRENT_TREND = 0

        debug(f"Current trend: {CURRENT_TREND}")

        if CURRENT_TREND != 0:
            if CURRENT_TREND == PREVIOUS_TREND:
                TREND_COUNT += 1
            else:
                TREND_COUNT = 1
                PREVIOUS_TREND = CURRENT_TREND
        else:
            TREND_COUNT = 0

        debug(f"Trend count: {TREND_COUNT}")

        CURRENT_GAIN_DB = get_gain_db(MICROPHONE_NAME)

        if CURRENT_GAIN_DB is None:
            print("Failed to get current gain level. Retrying in 1 minute...")
            time.sleep(60)
            continue

        debug(f"Current gain: {CURRENT_GAIN_DB} dB")

        if TREND_COUNT >= TREND_COUNT_THRESHOLD:
            if CURRENT_TREND == 1:
                # Decrease gain by 1 dB
                NEW_GAIN_DB = CURRENT_GAIN_DB - DECREASE_GAIN_STEP_DB
                if NEW_GAIN_DB < MIN_GAIN_DB:
                    NEW_GAIN_DB = MIN_GAIN_DB
                success = set_gain_db(MICROPHONE_NAME, NEW_GAIN_DB)
                if success:
                    print(f"Decreased gain to {NEW_GAIN_DB} dB")
                    debug(f"Gain adjusted to {NEW_GAIN_DB} dB")
                else:
                    print("Failed to set new gain.")
            elif CURRENT_TREND == -1:
                # Increase gain by 5 dB
                NEW_GAIN_DB = CURRENT_GAIN_DB + INCREASE_GAIN_STEP_DB
                if NEW_GAIN_DB > MAX_GAIN_DB:
                    NEW_GAIN_DB = MAX_GAIN_DB
                success = set_gain_db(MICROPHONE_NAME, NEW_GAIN_DB)
                if success:
                    print(f"Increased gain to {NEW_GAIN_DB} dB")
                    debug(f"Gain adjusted to {NEW_GAIN_DB} dB")
                else:
                    print("Failed to set new gain.")
            TREND_COUNT = 0
        else:
            debug("No gain adjustment needed.")

        # Sleep for 1 minute before the next iteration
        time.sleep(60)


if __name__ == "__main__":
    main()
```

</details>
