# BirdNET-PiPy add-on

## Installation

1. Add this repository to your Home Assistant add-on store.
2. Install the BirdNET-PiPy add-on.
3. Configure the options and start the add-on.
4. Open the Web UI.

## Access

- **Ingress:** Use the Home Assistant sidebar entry.
- **Direct:** `http://<host>:8099`

## Options

```yaml
TZ: Etc/UTC # Timezone, see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
ICECAST_PASSWORD: "" # Optional: set a persistent password for the audio stream
STREAM_BITRATE: 320k # Bitrate for the mp3 stream
RECORDING_MODE: rtsp # pulseaudio | http_stream | rtsp
RTSP_URL: "" # Required if RECORDING_MODE is rtsp
data_location: /config/data # Persistent data location for BirdNET-PiPy
```

## Audio

The add-on expects audio via PulseAudio (default) or an RTSP stream configured in the BirdNET-PiPy settings.
