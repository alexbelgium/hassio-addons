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

Author: OpenAI ChatGPT
Date: 2024-10-28 (Updated)

Changelog:
- 2024-10-27: Increased sampling rate to 48,000 Hz.
- 2024-10-27: Extended THD calculation over the full frequency range.
- 2024-10-27: Added gain stabilization delay to reduce frequent adjustments.
- 2024-10-27: Improved RTSP stream resilience with retry logic.
- 2024-10-27: Enhanced debug output with logging levels.
- 2024-10-28: Added summary log mode for simplified output.
- 2024-10-28: Removed gain stabilization delay for immediate gain adjustments.
"""

import subprocess
import numpy as np
from scipy.signal import butter, sosfilt, find_peaks
import time
import re

# ---------------------------- Configuration ----------------------------

# Microphone Settings
MICROPHONE_NAME = "Line In 1 Gain"
MIN_GAIN_DB = 20
MAX_GAIN_DB = 40
DECREASE_GAIN_STEP_DB = 1
INCREASE_GAIN_STEP_DB = 5
CLIPPING_REDUCTION_DB = 3

# Noise Thresholds
NOISE_THRESHOLD_HIGH = 0.001
NOISE_THRESHOLD_LOW = 0.00035

# Trend Detection
TREND_COUNT_THRESHOLD = 3

# Sampling Rate
SAMPLING_RATE = 44100

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

# -----------------------------------------------------------------------


def debug_print(msg, level="info"):
    """
    Prints debug messages with logging levels if DEBUG mode is enabled.
    :param msg: The debug message to print.
    :param level: Logging level - "info", "warning", "error".
    """
    if DEBUG:
        current_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        print(f"[{current_time}] [{level.upper()}] {msg}")


def summary_log(current_gain, clipping, rms_amplitude, thd_percentage):
    """
    Outputs a summary log with date, time, current gain, clipping status, background noise, and THD.
    :param current_gain: Current microphone gain in dB.
    :param clipping: Clipping status (yes/no).
    :param rms_amplitude: Background noise RMS amplitude.
    :param thd_percentage: THD in percentage.
    """
    if SUMMARY_MODE:
        current_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        clipping_status = "Yes" if clipping else "No"
        print(f"[{current_time}] [SUMMARY] Gain: {current_gain:.1f} dB | Clipping: {clipping_status} | "
              f"Noise: {rms_amplitude:.5f} | THD: {thd_percentage:.2f}%")


def get_gain_db(mic_name):
    """
    Retrieves the current gain setting of the specified microphone using amixer.
    """
    cmd = ['amixer', 'sget', mic_name]
    try:
        output = subprocess.check_output(cmd, stderr=subprocess.STDOUT).decode()
        match = re.search(r'\[(-?\d+(\.\d+)?)dB\]', output)
        if match:
            gain_db = float(match.group(1))
            debug_print(f"Retrieved gain: {gain_db} dB", "info")
            return gain_db
        else:
            debug_print("No gain information found in amixer output.", "warning")
            return None
    except subprocess.CalledProcessError as e:
        debug_print(f"amixer sget failed: {e}", "error")
        return None


def set_gain_db(mic_name, gain_db):
    """
    Sets the gain of the specified microphone using amixer.
    """
    gain_db_int = int(gain_db)
    if gain_db_int > MAX_GAIN_DB:
        debug_print(f"Requested gain {gain_db_int} dB exceeds MAX_GAIN_DB {MAX_GAIN_DB} dB. Skipping.", "warning")
        return False  # Do not exceed max gain
    cmd = ['amixer', 'sset', mic_name, f'{gain_db}dB']
    try:
        subprocess.check_call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
        debug_print(f"Set gain to: {gain_db} dB", "info")
        return True
    except subprocess.CalledProcessError as e:
        debug_print(f"amixer sset failed: {e}", "error")
        return False


def find_fundamental_frequency(fft_freqs, fft_magnitude, min_freq=2000, max_freq=8000):
    """
    Dynamically finds the fundamental frequency within a specified range.
    """
    idx_min = np.searchsorted(fft_freqs, min_freq)
    idx_max = np.searchsorted(fft_freqs, max_freq)
    if idx_max <= idx_min:
        return None, 0

    search_magnitude = fft_magnitude[idx_min:idx_max]
    search_freqs = fft_freqs[idx_min:idx_max]
    peaks, properties = find_peaks(search_magnitude, height=np.max(search_magnitude) * 0.1)
    if len(peaks) == 0:
        return None, 0

    max_peak_idx = np.argmax(properties['peak_heights'])
    fundamental_freq = search_freqs[peaks[max_peak_idx]]
    fundamental_amplitude = search_magnitude[peaks[max_peak_idx]]

    debug_print(f"Detected fundamental frequency: {fundamental_freq:.2f} Hz with amplitude {fundamental_amplitude:.4f}", "info")
    return fundamental_freq, fundamental_amplitude


def thd_calculation(audio, sampling_rate, num_harmonics=5):
    """
    Calculates Total Harmonic Distortion (THD) for the audio signal.
    """
    fft_vals = np.fft.rfft(audio)
    fft_freqs = np.fft.rfftfreq(len(audio), 1 / sampling_rate)
    fft_magnitude = np.abs(fft_vals)
    fundamental_freq, fundamental_amplitude = find_fundamental_frequency(fft_freqs, fft_magnitude)

    if fundamental_freq is None or fundamental_amplitude < 1e-6:
        debug_print("Fundamental frequency not detected or amplitude too low. Skipping THD calculation.", "warning")
        return 0.0

    harmonic_amplitudes = []
    for n in range(2, num_harmonics + 1):
        harmonic_freq = n * fundamental_freq
        if harmonic_freq > sampling_rate / 2:
            break
        harmonic_idx = np.argmin(np.abs(fft_freqs - harmonic_freq))
        harmonic_amp = fft_magnitude[harmonic_idx]
        harmonic_amplitudes.append(harmonic_amp)
        debug_print(f"Harmonic {n} frequency: {harmonic_freq:.2f} Hz, amplitude: {harmonic_amp:.4f}", "info")

    harmonic_sum = np.sqrt(np.sum(np.square(harmonic_amplitudes)))
    thd = (harmonic_sum / fundamental_amplitude) * 100 if fundamental_amplitude > 0 else 0.0
    debug_print(f"THD Calculation: {thd:.2f}%", "info")
    return thd


def calculate_spl(audio, mic_sensitivity_db):
    """
    Calculates the Sound Pressure Level (SPL) from the audio signal.
    """
    rms_amplitude = np.sqrt(np.mean(audio ** 2))
    if rms_amplitude == 0:
        debug_print("RMS amplitude is zero. SPL cannot be calculated.", "warning")
        return -np.inf

    mic_sensitivity_linear = 10 ** (mic_sensitivity_db / 20)
    pressure = rms_amplitude / mic_sensitivity_linear
    spl = 20 * np.log10(pressure / REFERENCE_PRESSURE)
    debug_print(f"Calculated SPL: {spl:.2f} dB", "info")
    return spl


def detect_microphone_overload(spl, mic_clipping_spl):
    """
    Detects if the calculated SPL is approaching the microphone's clipping SPL.
    """
    if spl >= mic_clipping_spl - 3:
        debug_print("Microphone overload detected.", "warning")
        return True
    return False


def calculate_noise_rms_and_thd(rtsp_url, bandpass_sos, sampling_rate, num_bins=5):
    """
    Captures audio from an RTSP stream, calculates RMS, THD, and SPL, and detects microphone overload.
    """
    cmd = [
        'ffmpeg', '-loglevel', 'error', '-rtsp_transport', 'tcp', '-i', rtsp_url,
        '-vn', '-f', 's16le', '-acodec', 'pcm_s16le', '-ar', str(sampling_rate), '-ac', '1', '-t', '5', '-'
    ]

    retries = 3
    for attempt in range(retries):
        try:
            debug_print(f"Attempt {attempt + 1} to capture audio from {rtsp_url}", "info")
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate()

            if process.returncode != 0:
                debug_print(f"ffmpeg failed with error: {stderr.decode()}", "error")
                time.sleep(5)
                continue

            audio = np.frombuffer(stdout, dtype=np.int16).astype(np.float32) / 32768.0
            debug_print(f"Captured {len(audio)} samples from audio stream.", "info")
            if len(audio) == 0:
                debug_print("No audio data captured.", "warning")
                time.sleep(5)
                continue

            filtered_audio = sosfilt(bandpass_sos, audio)
            rms_amplitude = np.sqrt(np.mean(filtered_audio ** 2))
            thd_percentage = thd_calculation(filtered_audio, sampling_rate)
            spl = calculate_spl(filtered_audio, MIC_SENSITIVITY_DB)
            overload = detect_microphone_overload(spl, MIC_CLIPPING_SPL)

            return rms_amplitude, thd_percentage, spl, overload

        except Exception as e:
            debug_print(f"Exception during audio processing: {e}", "error")
            time.sleep(5)  # Small delay before retrying

    return None, None, None, False


def main():
    """
    Main loop that continuously monitors background noise, detects clipping, calculates THD,
    and adjusts microphone gain with retry logic for RTSP stream resilience.
    """
    TREND_COUNT = 0
    PREVIOUS_TREND = 0

    # Precompute bandpass filter coefficients with updated SAMPLING_RATE
    LOWCUT = 2000
    HIGHCUT = 8000
    FILTER_ORDER = 5
    sos = butter(FILTER_ORDER, [LOWCUT, HIGHCUT], btype='band', fs=SAMPLING_RATE, output='sos')

    # Set the microphone gain to the maximum gain at the start
    success = set_gain_db(MICROPHONE_NAME, MAX_GAIN_DB)
    if success:
        print(f"Microphone gain set to {MAX_GAIN_DB} dB at start.")
    else:
        print("Failed to set microphone gain at start. Exiting.")
        return

    while True:
        rms, thd, spl, overload = calculate_noise_rms_and_thd(RTSP_URL, sos, SAMPLING_RATE)

        if rms is None:
            print("Failed to compute noise RMS. Retrying in 1 minute...")
            time.sleep(60)
            continue

        # Adjust gain if overload detected
        if overload:
            current_gain_db = get_gain_db(MICROPHONE_NAME)
            if current_gain_db is not None:
                NEW_GAIN_DB = max(current_gain_db - CLIPPING_REDUCTION_DB, MIN_GAIN_DB)
                if set_gain_db(MICROPHONE_NAME, NEW_GAIN_DB):
                    print(f"Clipping detected. Reduced gain to {NEW_GAIN_DB} dB")
                    debug_print(f"Gain reduced to {NEW_GAIN_DB} dB due to clipping.", "warning")
            # No stabilization delay; continue to next iteration
            # Skip trend adjustment in case of clipping
            summary_log(current_gain_db if current_gain_db else MIN_GAIN_DB, True, rms, thd)
            time.sleep(60)
            continue

        # Handle THD if SPL is above threshold
        if spl >= THD_FUNDAMENTAL_THRESHOLD_DB:
            if thd > MAX_THD_PERCENTAGE:
                debug_print(f"High THD detected: {thd:.2f}%", "warning")
                current_gain_db = get_gain_db(MICROPHONE_NAME)
                if current_gain_db is not None:
                    NEW_GAIN_DB = max(current_gain_db - DECREASE_GAIN_STEP_DB, MIN_GAIN_DB)
                    if set_gain_db(MICROPHONE_NAME, NEW_GAIN_DB):
                        print(f"High THD detected. Decreased gain to {NEW_GAIN_DB} dB")
                        debug_print(f"Gain decreased to {NEW_GAIN_DB} dB due to high THD.", "info")
            else:
                debug_print("THD within acceptable limits.", "info")
        else:
            debug_print("SPL below THD calculation threshold. Skipping THD check.", "info")

        # Determine the noise trend
        if rms > NOISE_THRESHOLD_HIGH:
            CURRENT_TREND = 1
        elif rms < NOISE_THRESHOLD_LOW:
            CURRENT_TREND = -1
        else:
            CURRENT_TREND = 0

        debug_print(f"Current trend: {CURRENT_TREND}", "info")

        if CURRENT_TREND != 0:
            if CURRENT_TREND == PREVIOUS_TREND:
                TREND_COUNT += 1
            else:
                TREND_COUNT = 1
                PREVIOUS_TREND = CURRENT_TREND
        else:
            TREND_COUNT = 0

        debug_print(f"Trend count: {TREND_COUNT}", "info")

        current_gain_db = get_gain_db(MICROPHONE_NAME)

        if current_gain_db is None:
            print("Failed to get current gain level. Retrying in 1 minute...")
            time.sleep(60)
            continue

        debug_print(f"Current gain: {current_gain_db} dB", "info")

        # Output summary log for the current state
        summary_log(current_gain_db, overload, rms, thd)

        # Adjust gain based on noise trend if threshold count is reached
        if TREND_COUNT >= TREND_COUNT_THRESHOLD:
            if CURRENT_TREND == 1 and int(current_gain_db) > MIN_GAIN_DB:
                # Decrease gain by DECREASE_GAIN_STEP_DB dB
                NEW_GAIN_DB = max(current_gain_db - DECREASE_GAIN_STEP_DB, MIN_GAIN_DB)
                if set_gain_db(MICROPHONE_NAME, NEW_GAIN_DB):
                    print(f"Background noise high. Decreased gain to {NEW_GAIN_DB} dB")
                    debug_print(f"Gain decreased to {NEW_GAIN_DB} dB due to high noise.", "info")
                TREND_COUNT = 0
            elif CURRENT_TREND == -1 and int(current_gain_db) < MAX_GAIN_DB:
                # Increase gain by INCREASE_GAIN_STEP_DB dB
                NEW_GAIN_DB = min(current_gain_db + INCREASE_GAIN_STEP_DB, MAX_GAIN_DB)
                if set_gain_db(MICROPHONE_NAME, NEW_GAIN_DB):
                    print(f"Background noise low. Increased gain to {NEW_GAIN_DB} dB")
                    debug_print(f"Gain increased to {NEW_GAIN_DB} dB due to low noise.", "info")
                TREND_COUNT = 0
        else:
            debug_print("No gain adjustment needed based on noise trend.", "info")

        # Sleep for 1 minute before the next iteration
        time.sleep(60)


if __name__ == "__main__":
    main()
```

</details>
