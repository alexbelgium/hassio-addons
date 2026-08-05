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
- "This costs 500 MB" → is it resident? `grep Rss /proc/<pid>/smaps`.
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
