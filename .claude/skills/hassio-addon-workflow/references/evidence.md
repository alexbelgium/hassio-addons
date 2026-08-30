# Evidence — measurement methodology and case studies

## Why summed RSS and reserved-vs-resident both matter

- **Summed RSS double-counts shared pages.** Removing a duplicate process frees its *private*
  memory, not its RSS. `scripts/measure.sh` reports PSS and private alongside RSS — quote
  **private** when arguing "removing this saves N MB".
- **A big mapping is not necessarily resident.** Large SysV/tmpfs segments are lazily populated;
  reserved size is reported separately from resident for this reason.
- `/proc/meminfo` and `free` show **host** figures (no memory cgroup namespace here) — never
  attribute those to the add-on.
- Sample duration matters: a 3 s CPU sample measured 2.3% where a 20 s sample measured 21.6% for
  the same process. Use ≥20 s for anything you report.

## Before asserting anything, ask what would show it false

- "This process is duplicated" → is it? `ps -ef --forest`, compare parents and start times.
- "This costs 500 MB" → is it resident? `grep Rss /proc/<pid>/smaps_rollup` — plain `smaps` prints
  one `Rss:` line per mapping (dozens of them), not a process total.
- "This block never runs" → is its payload in the image? `command -v`, `apt` history.
- "The flag isn't set" → `tr '\0' '\n' < /proc/<pid>/cmdline`.

When you correct yourself mid-analysis, keep the correction visible in your notes and in what you
report — a retracted claim that stays retracted is worth more than one quietly dropped.

## The failure mode this loop keeps producing

Every bug shipped from the source session came from one move: **measuring this host correctly,
then generalising it to all hosts.**

- `/dev/shm` was 7.7 GB here, so a flag looked useless — but Home Assistant ignores `shm_size`, so
  elsewhere it is Docker's 64 MB default and removing the flag reintroduces a crash loop.
- An MCP entry was identified by its URL — but that URL is the documented default, so the rule
  would have deleted a user's hand-written configuration.
- A GPU probe created a hardware context — but that proved the driver worked, not that Chromium's
  GPU path did.
- SABnzbd's source was grepped to see which proxy headers it reads, and `X-Forwarded-For` was
  forwarded because it reads that one — but `verify_xff_header` is on by default and makes it
  *reject* every address in the chain that is not local, so ingress answered 403 for anyone
  reaching Home Assistant from outside the LAN (#3019, fixed in #3023). Every check ran from
  inside the container, where no such header exists. **That an app reads a header is not a reason
  to send it — find out what it does with it, and exercise the path a remote user takes.**

The pattern is always *inference standing in for detection*. Before changing a default, ask what
this is like on a host unlike yours. Prefer detecting the condition at runtime over asserting it.
When ownership matters, **record it rather than infer it**.

## "Merged and inert" — CI passing proves the build works, not that the change does anything

Both changes in the session that produced this skill passed CI, merged, and were **inert**:

- The Xvfb resolution cap wrote its env file correctly and Xvfb still started at the base-image
  default — wrong env mechanism for that service.
- The GPU flags reached Chromium's command line exactly as intended, and the GPU process still
  reported `--use-gl=disabled`, having overridden them after its own init failed.

Once the rebuilt add-on is running, re-run the measurement that motivated the work. Some fixes
cannot be self-verified — a service that reads its environment only at start makes an env-var fix
unproven until the add-on restarts, which needs the user or `ha-cli` with their agreement. If you
cannot restart, the change is **Assumed**, not Verified, and must be reported that way.

## When your change is blamed for a regression, ask for a version rollback first

PR #3026 added an nginx `sub_filter` to the `filebrowser_quantum` ingress vhost. Right after it
merged the user reported Download had broken — the file opened inline instead of downloading — and
confirmed it still worked on the add-on's direct port, which serves `direct.conf` and carries no
`sub_filter`. That made the filter the only ingress-side change in the update, so PR #3028 reverted
it. Meanwhile every measurement said the filter was not involved:

- the shipped bundle's Download action builds an `<a href>` and clicks it, and never calls
  `window.open`, which is all the injected shim overrides;
- the shim's own predicate, evaluated live in the running app, returned false for the download
  URL, the `inline=true` raw URL and the public-share download URL;
- the download response through the vhost was **byte-identical** with and without the `sub_filter`
  (`Content-Disposition: attachment` intact, `Content-Length` unchanged), for `text/plain` and for
  the `text/html` case the filter actually scans;
- upstream's frontend download code is unchanged from v1.5.0-stable to v1.5.4-stable; Supervisor's
  ingress proxy forwards `Content-Disposition` (`_response_header` drops only `Transfer-Encoding`,
  `Content-Length`, `Content-Type`, `Content-Encoding`); and the ingress panel's iframe carries no
  `sandbox` attribute, so downloads are not sandbox-blocked.

The measurements were right. The user then rolled their add-on back to **1.5.3**, which predates the
filter, saw the identical behaviour, and the revert was closed unmerged.

**The lesson is about sequencing, not about who was right.** "Works on the old version, breaks on the
new one" is the only cheap experiment that actually isolates a shipped change, and only the reporter
can run it. Ask for it *first* — before building a reproduction, before opening a revert. It costs
them one add-on downgrade and it either confirms the regression or, as here, redirects the whole
investigation. A revert is the fallback for when they cannot roll back, not the opening move.

Two corollaries:

- **Do not let a clean local reproduction settle it either.** Being unable to reproduce is not
  evidence of absence, and the reporter watching it fail on their own instance outranks it. Both
  sides of that needed the rollback to resolve.
- **`build_from: <image>:latest` means every merge ships an upstream version bump too**, so "it
  broke when your PR landed" never implicates the diff on its own. Record which upstream version
  each add-on image was built from — the registry config blob's `created` timestamp, the resolved
  manifest digest, and the binary's version string. Here: add-on 1.5.3 was built 2026-08-28 23:29
  UTC from upstream v1.5.3-stable, 1.5.3.1 on 2026-08-30 06:00 UTC from v1.5.4-stable
  (`sha256:e549e1a9…`). If you do use a revert as the experiment, both builds must resolve the same
  upstream digest or it proves nothing:

  ```bash
  T=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:<repo>:pull" | jq -r .token)
  curl -s -H "Authorization: Bearer $T" \
       -H "Accept: application/vnd.oci.image.index.v1+json" \
       "https://registry-1.docker.io/v2/<repo>/manifests/latest" \
    | jq -r '.manifests[] | select(.platform.architecture=="amd64" and .platform.os=="linux") | .digest'
  ```

Worth building anyway, because it is reusable and needs no dockerd: a reproduction rig made **out of
the published image's own layers**. Pull the manifest and blobs from the registry with `curl` + `jq`,
untar them in order, then run the extracted binary through the image's own musl loader
(`root/lib/ld-musl-x86_64.so.1 ./filebrowser`) with the real `http/dist` next to it. Put the add-on's
rendered `ingress.conf` in front of it, and a second nginx in front of that to strip the
`/api/hassio_ingress/<token>` prefix the way Supervisor does. That gets the real frontend, the real
backend and the real vhost under a browser — everything except Supervisor itself. Plain `tar` does
not interpret whiteouts, so a file a later layer deletes (`.wh.<name>`) or a directory it marks
opaque (`.wh..wh..opq`) survives into the reconstructed rootfs; check with
`tar tzf <layer> | grep '\.wh\.'` and reach for an OCI-aware unpacker if any turn up.
