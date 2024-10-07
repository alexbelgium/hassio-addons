I've tested lots of settings by running 2 versions of my HA birdnet-pi addon in parallel using the same rtsp feed, and comparing impact of parameters. 
My conclusions aren't universal, as it seems to be highly dependent on the region and type of mic used. For example, the old model seems to be better in Australia, while the new one better in Europe.

# Microphone considerations
The critical element is the microphone quality : a Boya By-lm 40 or clippy EM272 (with a very good aux-usb converter) is key to improve the quality of detections. 
Here is some example tests I did (whole threads are really interesting also): https://github.com/mcguirepr89/BirdNET-Pi/discussions/39#discussioncomment-9706951 
https://github.com/mcguirepr89/BirdNET-Pi/discussions/1092#discussioncomment-9706191

My recommendation :
- Best entry system (< 50€) : Boya By-lm40 (30€) + deadcat (10 €)
- Best middle end system (< 150 €) : Clippy EM272 (55€) + Rode AI micro trrs to usb (70€) + Rycote deadcat (27€)
- Best high end system (<300 €) : Clippy EM272 XLR (85€) or LOM Ucho Pro (75€) + Focusrite Scarlet 2i2 4th Gen (200€) + Rycote/Bubblebee deadcat

# App settings recommendation
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
### On your desktop
Download imager
Install raspbian lite 64

### With ssh, install requisite softwares
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

### Modify config.txt

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

### Optional : install Focusrite driver
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

### Find right device
```
# List audio devices
arecord -l

# Check audio device parameters. Example :
arecord -D hw:1,0 --dump-hw-params
```

### Add startup script
sudo nano startmic.sh
```
#!/bin/bash
echo "Starting birdmic"
# Disable gigabit ethernet
sudo ethtool -s eth0 speed 100 duplex full autoneg on
# Start rtsp server
./mediamtx & true
# Create rtsp feed
sleep 5
# Using hw
# ffmpeg -nostdin -f alsa -acodec pcm_s16le -ac 2 -ar 48000 -i hw:0,0 -f rtsp -acodec pcm_s16le rtsp://localhost:8554/birdmic -rtsp_transport tcp || true & true
# Using plughw
ffmpeg -nostdin -f alsa -acodec pcm_s32le -ac 2 -ar 48000 -i plughw:0,0 -f rtsp -acodec pcm_s16be rtsp://localhost:8554/birdmic -rtsp_transport tcp -buffer_size 512k || ffmpeg -nostdin -f alsa -acodec pcm_s32le -ac 2 -ar 48000 -i plughw:1,0 -f rtsp -acodec pcm_s16be rtsp://localhost:8554/birdmic -rtsp_transport tcp -buffer_size 512k || true & true
# Using plughw with high, lowpass, and limit to avoid clipping
ffmpeg -nostdin -f alsa -acodec pcm_s32le -ac 2 -ar 48000 -i plughw:0,0 -af "highpass=f=100, lowpass=f=15000, alimiter=limit=1.0:attack=5:release=50" -f rtsp -acodec pcm_s16be rtsp://localhost:8554/birdmic -rtsp_transport tcp -buffer_size 512k || true & true

# Set microphone volume
sleep 5
MICROPHONE_NAME="Line In 1 Gain" # for Focusrite Scarlett 2i2
amixer -c 0 sset "$MICROPHONE_NAME" 30%

```

Startup automatically
```
chmod +x startmic.sh
crontab -e # select nano as your editor
```
Paste in `@reboot $HOME/startmic.sh` then save and exit nano.
Reboot the Pi and test again with VLC to make sure the RTSP stream is live.

### Configuration for Focusrite Scarlett 2i2

```
#!/bin/bash

# Set PCM controls for capture
amixer -c 0 cset numid=31 'Analogue 1'  # 'PCM 01' - Set to 'Analogue 1'
amixer -c 0 cset numid=32 'Analogue 1'  # 'PCM 02' - Set to 'Analogue 1'
amixer -c 0 cset numid=33 'Off'         # 'PCM 03' - Disabled
amixer -c 0 cset numid=34 'Off'         # 'PCM 04' - Disabled

# Set DSP Input controls (Unused, set to Off)
amixer -c 0 cset numid=29 'Off'         # 'DSP Input 1'
amixer -c 0 cset numid=30 'Off'         # 'DSP Input 2'

# Configure Line In 1 as main input for mono setup
amixer -c 0 cset numid=8 'Off'          # 'Line In 1 Air' - Keep 'Off'
amixer -c 0 cset numid=14 off           # 'Line In 1 Autogain' - Disabled
amixer -c 0 cset numid=13 80%            # 'Line In 1 Gain' - Set gain to 21
amixer -c 0 cset numid=6 'Line'         # 'Line In 1 Level' - Set level to 'Line'
amixer -c 0 cset numid=21 on           # 'Line In 1 Safe' - Enabled to avoid clipping / noise impact ?

# Disable Line In 2 to minimize interference (if not used)
amixer -c 0 cset numid=9 'Off'          # 'Line In 2 Air'
amixer -c 0 cset numid=17 off           # 'Line In 2 Autogain' - Disabled
amixer -c 0 cset numid=16 0             # 'Line In 2 Gain' - Set gain to 0 (mute)
amixer -c 0 cset numid=7 'Line'         # 'Line In 2 Level' - Set to 'Line'
amixer -c 0 cset numid=22 off           # 'Line In 2 Safe' - Disabled

# Set Line In 1-2 controls
amixer -c 0 cset numid=12 off           # 'Line In 1-2 Link' - No need to link for mono
amixer -c 0 cset numid=10 on            # 'Line In 1-2 Phantom Power' - Enabled for condenser mics

# Set Analogue Outputs to use the same mix for both channels (Mono setup)
amixer -c 0 cset numid=23 'Mix A'       # 'Analogue Output 01' - Set to 'Mix A'
amixer -c 0 cset numid=24 'Mix A'       # 'Analogue Output 02' - Same mix as Output 01

# Set Direct Monitor to off to prevent feedback
amixer -c 0 cset numid=53 'Off'         # 'Direct Monitor'

# Set Input Select to Input 1
amixer -c 0 cset numid=11 'Input 1'     # 'Input Select'

# Optimize Monitor Mix settings for mono output
amixer -c 0 cset numid=54 153           # 'Monitor 1 Mix A Input 01' - Set to 153 (around -3.50 dB)
amixer -c 0 cset numid=55 153           # 'Monitor 1 Mix A Input 02' - Set to 153 for balanced output
amixer -c 0 cset numid=56 0             # 'Monitor 1 Mix A Input 03' - Mute unused channels
amixer -c 0 cset numid=57 0             # 'Monitor 1 Mix A Input 04'

# Set Sync Status to Locked
amixer -c 0 cset numid=52 'Locked'      # 'Sync Status'

echo "Mono optimization applied. Only using primary input and balanced outputs."
```
