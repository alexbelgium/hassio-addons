# Transmission addon for Hass.io

The torrent client for Hass.io with OpenVPN support.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. Add https://github.com/pierrickrouxel/hassio-addon-transmission.git to your Hass.io instance as a repository.
1. Install the "Transmission" add-on.
1. Start the "Transmission" add-on.
1. Check the logs of the "Tranmission" to see if everything went well.
1. Open the web-ui

## Configuration

**Note**: _Remember to restart the add-on when the configuration is changed._

Transmission add-on configuration:

```json
{
  "log_level": "info",
  "authentication_required": false,
  "username": "",
  "password": "",
  "openvpn_enabled": false,
  "openvpn_config": "",
  "openvpn_username": "",
  "openvpn_password": ""
}
```

### Option: `log_level`

The `log_level` option controls the level of log output by the addon and can
be changed to be more or less verbose, which might be useful when you are
dealing with an unknown issue. Possible values are:

- `trace`: Show every detail, like all called internal functions.
- `debug`: Shows detailed debug information.
- `info`: Normal (usually) interesting events.
- `warning`: Exceptional occurrences that are not errors.
- `error`:  Runtime errors that do not require immediate action.
- `fatal`: Something went terribly wrong. Add-on becomes unusable.

Please note that each level automatically includes log messages from a
more severe level, e.g., `debug` also shows `info` messages. By default,
the `log_level` is set to `info`, which is the recommended setting unless
you are troubleshooting.

### Option: `authentication_required`

This option can be used to password protect the web-ui.

### Option: `username`

The username for authentication.

### Option: `password`

The password for authentication.

### Option: `openvpn_enabled`

Enable OpenVPN to anonymize your torrent activity.

### Option: `openvpn_config`

The name of .ovpn file. You should put it in `/config/openvpn`.

### Option: `openvpn_username`

Your OpenVPN username.

### Option: `openvpn_password`

Your OpenVPN password.

## Embedding into Home Assistant

This addon supports ingress, thus it can simply be integrated into Home Assistant without having to forward any additional ports. Here is an example configuration:

```yaml
transmission:
  host: f6fddefc-transmission
```

If you want, you can add an icon to the sidebar by toggling *Show in Sidebar* as well.

## Changelog & Releases

The format of the log is based on
[Keep a Changelog](http://keepachangelog.com/en/1.0.0/).

Releases are based on [Semantic Versioning](http://semver.org/spec/v2.0.0.html), and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## License

MIT License

Copyright (c) 2018 Pierrick Rouxel

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
