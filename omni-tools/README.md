# Home Assistant Add-on: Omni Tools

## About

Omni Tools is a self-hosted web application offering a variety of online utilities for everyday tasks. All file processing is done entirely client-side, ensuring privacy and security.

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield]

## Features

- **Image Tools**: Image resizer, converter
- **Video Tools**: Video trimmer
- **PDF Tools**: PDF splitter, merger
- **Text/List Tools**: Various text manipulation utilities
- **Date and Time Tools**: Date/time calculators and converters
- **Math Tools**: Mathematical calculators and converters
- **Data Tools**: JSON, CSV, XML processors

## Installation

1. Add this repository to your Home Assistant Supervisor add-on store
2. Install the "Omni Tools" add-on
3. Start the add-on
4. Open the web UI

## Configuration

### Option: `PUID`

User ID to run the application with. Default is `0`.

### Option: `PGID`

Group ID to run the application with. Default is `0`.

### Option: `TZ`

Timezone setting for the application.

## Usage

1. Access the web interface through the Home Assistant sidebar or by navigating to the add-on's web UI
2. Choose from various tool categories:
   - Image/Video/Audio processing
   - PDF manipulation
   - Text and list processing
   - Date and time utilities
   - Mathematical tools
   - Data format conversions

All processing is done locally in your browser for maximum privacy and security.

## Support

Got questions?

You have several options to get them answered:

- The [Home Assistant Discord Chat Server][discord]
- The Home Assistant [Community Forum][forum]
- Join the [Reddit subreddit][reddit] in [/r/homeassistant][reddit]

## Authors & contributors

The original setup of this repository is by [Alex Belgium][alexbelgium].

## License

MIT License

Copyright (c) 2017-2024 Alex Belgium

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[alexbelgium]: https://github.com/alexbelgium
[discord]: https://discord.gg/c5DvZ4e
[forum]: https://community.home-assistant.io
[reddit]: https://reddit.com/r/homeassistant