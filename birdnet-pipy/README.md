# Home assistant add-on: BirdNET-PiPy

BirdNET-PiPy is a self-hosted system that uses the BirdNET deep-learning model to identify birds from their sounds, with a modern web dashboard for monitoring detections. This add-on packages the upstream project for Home Assistant with ingress support.

## About

- Upstream project: https://github.com/Suncuss/BirdNET-PiPy
- This add-on runs the BirdNET-PiPy backend services, Icecast audio stream, and Vue.js frontend in a single container.

## Configuration

```yaml
TZ: Etc/UTC
ICECAST_PASSWORD: "" # Optional: set a persistent password for the audio stream
STREAM_BITRATE: 320k # Bitrate for the mp3 stream
```

After starting, open the add-on web UI. Use the BirdNET-PiPy settings page to configure location, audio source, and other options.

## Notes

- Audio input uses Home Assistant's PulseAudio server by default.
- Ingress is enabled; direct access is available on the configured port.
