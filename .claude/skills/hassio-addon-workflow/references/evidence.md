# Evidence — measurement methodology and case studies

## How to read the numbers

**Summed RSS overstates savings.** Shared library pages are counted once per process, so removing
a duplicate frees its *private* memory, not its RSS. Measured example: four MCP shims summed to
882 MB RSS but 643 MB PSS / 564 MB private, and per-process private ranged 54 MB down to 2 MB —
which completely changes which duplicate is worth removing. Quote private when arguing "removing
this saves N MB".

**A large mapping is often not resident.** SysV/tmpfs segments are lazily populated. Xvfb's
506 MB framebuffer shows `Rss: 0` in `/proc/<pid>/smaps`. Check before calling anything a leak.

**`/proc/meminfo` and `free` show host figures** — there is no memory cgroup namespace here.
Never attribute those totals to the add-on.

**A short CPU sample is not a CPU measurement.** A 3 s sample measured 2.3% where a 20 s sample
measured 21.6% for the same process. Use >= 20 s for anything you report.

`scripts/measure.sh` already reports PSS and private alongside RSS, and resident separately from
reserved, so these three only bite when you compute a figure yourself or quote one from `ps`.

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
