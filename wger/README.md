
# Hass.io Add-ons: Wger


I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fwger%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fwger%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fwger%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/wger/stats.png)

## About

[wger](https://github.com/wger-project/wger) Workout Manager is a free, open source web application that helps you manage your personal workouts, weight and diet plans and can also be used as a simple gym management utility. It offers a REST API as well, for easy integration with other projects and tools.

## Configuration

Use the add-on `env_vars` option to pass extra environment variables (uppercase or lowercase names). See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

- Start the addon. Wait a while and check the log for any errors. Initial start can take up to 15 minutes !
- Open yourdomain.com:9927 (default host mapping for the add-on port `80/tcp`, as indicated by the `webui` hint).
- Default
  - Username: `admin`
  - Password: `adminadmin`

Options can be configured through two ways :

- Addon options

```yaml
"CONFIG_LOCATION": location of the config.yaml # Sets the location of the config.yaml (see below)
```

- Config.yaml (advanced usage)

Additional variables can be set as ENV variables by adding them in the config.yaml in the location defined in your addon options according to this guide : https://github.com/alexbelgium/hassio-addons/wiki/Addons-feature:-add-env-variables

The complete list of ENV variables can be seen here : not available

## Mobile app offline sync (PowerSync)

The official wger mobile app (2.0.3 and newer) syncs offline through a
[PowerSync](https://powersync.com/) service, which it expects to find at
`<SITE_URL>/ps/`. The add-on ships that service and can run it alongside wger, off by
default. Turn it on with the `POWERSYNC_ENABLED` option.

### Switching to PostgreSQL, and switching back

PowerSync cannot replicate from SQLite, which is what this add-on uses by default, and
wger's integration with it is built around PostgreSQL. Enabling PowerSync therefore means
pointing wger at a PostgreSQL database — and the add-on moves your data across for you.

The first time you start it with PowerSync enabled, the add-on copies the contents of its
SQLite database into the PostgreSQL one. Two things are guaranteed about that:

- **The SQLite database is never written to.** It is copied first, and everything is read
  from the copy, so the original is left byte for byte as it was. Removing
  `PS_DATABASE_URI` again puts wger straight back onto it — remove it from *everywhere*
  you set it, both the `env_vars` option and the `CONFIG_LOCATION` file, since either
  one takes precedence over the SQLite default.
- **An import only ever happens into an empty PostgreSQL database.** "Empty" here means
  one with no user accounts at all, which is wger's own test for a database that was
  never set up. So if you turn PowerSync off and on again later, whatever is already in
  PostgreSQL is left alone and nothing is overwritten.

What the import does not do is keep the two databases in step. After the switch,
PostgreSQL is the live database and the SQLite file is a frozen copy of the moment you
switched. If you go back to SQLite, anything you did in the meantime stays in PostgreSQL,
and vice versa. You will also be logged out of the web interface once, because sessions
are deliberately not carried over.

If the import cannot finish — the database is unreachable, or the copy or the load fails
— the add-on says so in the log, does not start PowerSync, and leaves the SQLite database
alone. One case is worth knowing about: if PostgreSQL never becomes reachable at all, your
data is not imported, and wger will go on to set the empty PostgreSQL database up as a
brand new instance. Fix the connection and restart the add-on before using wger if you
see that in the log.

### What you need

1. A PostgreSQL server the add-on can reach — the **Postgres 17** add-on from this
   repository works. PowerSync reads the logical write-ahead log, so the server needs
   `wal_level = logical`, which is not the default. With the Postgres add-on, add

   ```conf
   wal_level = logical
   ```

   to the file its `CONFIG_LOCATION` option points at, then restart it. The add-on
   checks this on startup and tells you in the log if it is still `replica`.
2. A database and a role for wger. PowerSync's bucket storage lives in a dedicated role
   and schema inside that same database, and the add-on creates them on every startup
   with upstream's idempotent `manage.py setup-powersync-storage`. The wger role
   therefore needs `CREATEROLE`, and `CREATE` on the database, **for as long as
   PowerSync is enabled** — not just for the first start:

   ```sql
   ALTER ROLE wger CREATEROLE;
   GRANT CREATE ON DATABASE wger TO wger;
   ```

   The same role — the one in `PS_DATABASE_URI`, not `powersync_storage` — also needs
   `REPLICATION`, which is how PowerSync reads the logical WAL:

   ```sql
   ALTER ROLE wger REPLICATION;
   ```

   On PostgreSQL 16 and later — which includes the Postgres 17 add-on — that is still not
   quite enough. Creating the schema runs `CREATE SCHEMA ... AUTHORIZATION
   powersync_storage`, and
   [the documentation](https://www.postgresql.org/docs/17/sql-createschema.html) requires
   that you "must be able to SET ROLE to that role". A `CREATEROLE` user is only given
   `ADMIN OPTION` on the roles it creates, not `SET`, because
   [`createrole_self_grant`](https://www.postgresql.org/docs/17/runtime-config-client.html#GUC-CREATEROLE-SELF-GRANT)
   defaults to empty. Grant it for the roles wger is about to create:

   ```sql
   ALTER ROLE wger SET createrole_self_grant = 'set, inherit';
   ```

   If the storage role already exists from an earlier attempt, grant it directly instead
   — this one has to be run by a role allowed to hand out that membership, normally the
   superuser:

   ```sql
   GRANT powersync_storage TO wger WITH ADMIN OPTION, SET TRUE;
   ```

   The PostgreSQL superuser has all of this already, which is why pointing at it works
   and is the quickest way to get going, but a role with just these grants is the better
   choice.
3. The URL your phone uses to reach wger, in `SITE_URL`. The app is handed
   `<SITE_URL>/ps/` as its sync endpoint, so a LAN-only address will not work from
   outside your network.

### Add-on configuration

Set `POWERSYNC_ENABLED` to `true` and add the following through the add-on's `env_vars`
option (the `CONFIG_LOCATION` config.yaml file documented above works for these too):

```yaml
env_vars:
  - name: PS_DATABASE_URI
    value: postgres://wger:yourpassword@192.168.1.10:5432/wger
  - name: PS_STORAGE_PG_URI
    value: postgres://powersync_storage:anotherpassword@192.168.1.10:5432/wger
  - name: SITE_URL
    value: https://wger.yourdomain.com
```

- `PS_DATABASE_URI` is wger's own database. Setting it takes precedence over the
  `DJANGO_DB_*` variables, so this single value both moves wger onto PostgreSQL and tells
  PowerSync what to replicate: in the shipped configuration they read the same URI, so
  they cannot be pointed at different databases by accident.
- `PS_STORAGE_PG_URI` is PowerSync's bucket storage. Point it at the **same** database
  with a different role name and a password of your choosing; that is the role the
  add-on creates. It must be set, it has no useful default.
- `SITE_URL` must be an absolute `http://` or `https://` URL with no path.

Set these through the `env_vars` option rather than the `CONFIG_LOCATION` file if the
password contains a `$` or a backtick. Both routes work, but the config.yaml route
writes the value unquoted into the add-on's environment file, where the shell expands
those characters and silently truncates the password — wger would get the mangled value
too, not just PowerSync.

> **The two URIs contain passwords, and the add-on prints every variable it loads to its
> log at startup.** The shared startup code masks values whose variable name looks like a
> secret, and these two names do not, so both PostgreSQL passwords appear in the add-on
> log in full — including when the value comes from `!secret`. Treat the add-on log as
> sensitive, and prefer a dedicated wger role with a password you are willing to see
> there over reusing credentials from elsewhere.

The add-on generates the RS256 JWT keypair the app and PowerSync need on first start and
keeps it at `/data/powersync/jwt.env`, so app sessions survive restarts. If you would
rather manage it yourself, generate one with
`python3 manage.py generate-jwt-keys` and pass both `JWT_PUBLIC_KEY` and
`JWT_PRIVATE_KEY` as env vars — both halves or neither.

Your PostgreSQL server also has to be a version PowerSync supports, and the sync rules
shipped with the add-on come from the upstream wger project. If replication fails for a
reason other than `wal_level`, the add-on log carries PowerSync's own error.

### Checking it works

With everything in place the add-on log reports the PowerSync URL, and
`<SITE_URL>/ps/probes/liveness` answers instead of logging `Not Found: /ps/probes/liveness`.
If a prerequisite is missing the add-on still starts wger normally and the log says
exactly which variable is wrong; `/ps/` stays unrouted in that case.

If you put your own reverse proxy in front of the add-on, nothing extra is needed: the
`/ps/` route forwards an incoming `X-Forwarded-Proto` unchanged and only falls back to
its own scheme when there is none, so PowerSync sees the external scheme your proxy
terminated.

### Licence

The bundled PowerSync service is published by Journey Mobile, Inc. under the
[Functional Source License 1.1 with an Apache 2.0 future grant](https://www.powersync.com/legal/fsl)
(FSL-1.1-ALv2). Its licence text ships in the image at `/opt/powersync/LICENSE`. The
service is pinned to a specific upstream release rather than tracking `latest`.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

## Support

If you have in issue with your installation, please be sure to checkout github.

[repository]: https://github.com/alexbelgium/hassio-addons

