# BirdNET-PiPy add-on

## Installation

1. Add this repository to your Home Assistant add-on store.
2. Install the BirdNET-PiPy add-on.
3. Configure the options and start the add-on.
4. Open the Web UI.

## Access

- **Ingress:** Use the Home Assistant sidebar entry.
- **Direct:** `http://<host>:8011` (or the port you configure)

## Options

```yaml
ICECAST_PASSWORD: "" # Optional: persistent password for the Icecast audio stream
data_location: /config/data # Persistent data location (under /config, /share, or /data)
env_vars: # Optional: extra environment variables
  - name: STREAM_BITRATE
    value: 320k # Icecast mp3 stream bitrate (default 320k)
```

## Audio

The add-on expects audio via PulseAudio (default) or an RTSP stream. Pick the source in the BirdNET-PiPy Web UI under **Settings → Audio** after the add-on first starts.
