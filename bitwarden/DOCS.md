# Home Assistant Community Add-on: Bitwarden RS

Bitwarden is an open-source password manager that can store sensitive
information such as website credentials in an encrypted vault.

The Bitwarden platform offers a variety of client applications including
a web interface, desktop applications, browser extensions and mobile apps.

This add-on is based upon the lightweight and opensource
[Bitwarden RS][bitwarden-rs] implementation, allowing you to self-host
this amazing password manager.

Password theft is a serious problem. The websites and apps that you use are
under attack every day. Security breaches occur and your passwords are stolen.
When you reuse the same passwords everywhere hackers can easily access your
email, bank, and other important accounts. USE A PASSWORD MANAGER!

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Home Assistant add-on.

1. Search for the "Bitwarden RS" add-on in the Supervisor add-on store and
   install it.
1. Start the "Bitwarden RS" add-on.
1. Check the logs of the "Bitwarden RS" add-on to see if everything went
   well and to get the admin token/password.
1. Click the "OPEN WEB UI" button to open Bitwarden RS.
1. Add `/admin` to the URL to access the admin panel, e.g.,
   `http://hassio.local:7277/admin`. Log in using the admin token you got
   in step 3.
1. The admin/token in the logs is only shown until it is saved or changed.
   Hit save in the admin panel to use the randomly generated password or
   change it to one of your choosing.
1. Be sure to store your admin token somewhere safe.

## Configuration

**Note**: _Remember to restart the add-on when the configuration is changed._

Example add-on configuration:

```yaml
log_level: info
ssl: false
certfile: fullchain.pem
keyfile: privkey.pem
request_size_limit: 10485760
```

**Note**: _This is just an example, don't copy and paste it! Create your own!_

### Option: `log_level`

The `log_level` option controls the level of log output by the addon and can
be changed to be more or less verbose, which might be useful when you are
dealing with an unknown issue. Possible values are:

- `trace`: Show every detail, like all called internal functions.
- `debug`: Shows detailed debug information.
- `info`: Normal (usually) interesting events.
- `warning`: Exceptional occurrences that are not errors.
- `error`: Runtime errors that do not require immediate action.
- `fatal`: Something went terribly wrong. Add-on becomes unusable.

Please note that each level automatically includes log messages from a
more severe level, e.g., `debug` also shows `info` messages. By default,
the `log_level` is set to `info`, which is the recommended setting unless
you are troubleshooting.

### Option: `ssl`

Enables/Disables SSL (HTTPS). Set it `true` to enable it, `false` otherwise.

**Note**: _The SSL settings only apply to direct access and has no effect
on the Ingress service._

### Option: `certfile`

The certificate file to use for SSL.

**Note**: _The file MUST be stored in `/ssl/`, which is the default_

### Option: `keyfile`

The private key file to use for SSL.

**Note**: _The file MUST be stored in `/ssl/`, which is the default_

### Option: `request_size_limit`

By default the API calls are limited to 10MB. This should be sufficient for
most cases, however if you want to support large imports, this might be
limiting you. On the other hand you might want to limit the request size to
something smaller than that to prevent API abuse and possible DOS attack,
especially if running with limited resources.

To set the limit, you can use this setting: 10MB would be `10485760`.

## Known issues and limitations

- This add-on cannot support Ingress at this time due to technical limitations
  of the Bitwarden Vault web interface.
- Some web browsers, like Chrome, disallow the use of Web Crypto APIs in
  insecure contexts. In this case, you might get an error like
  `Cannot read property 'importKey'`. To solve this problem, you need to enable
  SSL and access the web interface using HTTPS.

## Changelog & Releases

This repository keeps a change log using [GitHub's releases][releases]
functionality. The format of the log is based on
[Keep a Changelog][keepchangelog].

Releases are based on [Semantic Versioning][semver], and use the format
of `MAJOR.MINOR.PATCH`. In a nutshell, the version will be incremented
based on the following:

- `MAJOR`: Incompatible or major changes.
- `MINOR`: Backwards-compatible new features and enhancements.
- `PATCH`: Backwards-compatible bugfixes and package updates.

## Support

Got questions?

You have several options to get them answered:

- The [Home Assistant Community Add-ons Discord chat server][discord] for add-on
  support and feature requests.
- The [Home Assistant Discord chat server][discord-ha] for general Home
  Assistant discussions and questions.
- The Home Assistant [Community Forum][forum].
- Join the [Reddit subreddit][reddit] in [/r/homeassistant][reddit]

You could also [open an issue here][issue] GitHub.

## Authors & contributors

The original setup of this repository is by [Franck Nijhof][frenck].

For a full list of all authors and contributors,
check [the contributor's page][contributors].

## License

MIT License

Copyright (c) 2019-2020 Franck Nijhof

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

[bitwarden-rs]: https://github.com/dani-garcia/bitwarden_rs
[contributors]: https://github.com/hassio-addons/addon-bitwarden/graphs/contributors
[discord-ha]: https://discord.gg/c5DvZ4e
[discord]: https://discord.me/hassioaddons
[forum]: https://community.home-assistant.io/t/home-assistant-community-add-on-bitwarden-rs/115573?u=frenck
[frenck]: https://github.com/frenck
[issue]: https://github.com/hassio-addons/addon-bitwarden/issues
[keepchangelog]: http://keepachangelog.com/en/1.0.0/
[reddit]: https://reddit.com/r/homeassistant
[releases]: https://github.com/hassio-addons/addon-bitwarden/releases
[semver]: http://semver.org/spec/v2.0.0.htm
