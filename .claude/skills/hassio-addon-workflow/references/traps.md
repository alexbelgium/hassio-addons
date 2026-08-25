# Repo-specific traps

Things that look correct and are not. Each cost real time or shipped broken. Read this before
implementing; skim the headings, read the ones you're about to touch.

The repo's own `CLAUDE.md` documents structure, Dockerfile conventions, `updater.json`, CI
workflows and lint rules — that is not repeated here.

## Contents

- [Environment and workspace](#environment-and-workspace)
- [Measurement](#measurement)
- [Passing values into base-image services](#passing-values-into-base-image-services)
- [Writing into an app's own config](#writing-into-an-apps-own-config)
- [Shell and bashio](#shell-and-bashio)
- [Dockerfile and architecture](#dockerfile-and-architecture)
- [Versioning](#versioning)
- [Chromium / Electron under Xvfb](#chromium--electron-under-xvfb)
- [CI and review bots](#ci-and-review-bots)

---

## Environment and workspace

**The checkout is probably on the wrong branch.** Checkouts under `/data/claude` are shared and
persistent; another session leaves them wherever it finished. A stale branch looks entirely
normal. Compare the add-on's `config.yaml` `version` against the running `$BUILD_VERSION` before
trusting anything you read. `scripts/preflight.sh` does this.

**Never run `git stash` under `/data/claude`.** `refs/stash` is shared across every worktree and
concurrent session, so it is *not* isolated even in your own worktree. A bare `stash` / `stash
pop` pair in a clean worktree once restored another session's stash, producing conflict markers
in six untouched files. To compare a file against another revision use
`git show <rev>:<path> > /tmp/x`. If a pop does go wrong: a conflicted pop **keeps** the stash
entry, so nothing is lost — confirm `git rev-parse HEAD` matches what you pushed, then
`git reset --hard HEAD`.

**Work in a worktree under `/data`, not `/tmp`** — `/tmp` is `noexec`, so scripts there won't run.

```bash
git worktree add --detach /data/claude/.work/<task> origin/master
```

**You cannot test the Docker build.** dockerd does not start in this environment. CI is the only
gate. One observed run took ~3 hours, with 20+ runs queued against 2 executing — that was account
runner contention, not the diff. Check `gh run list` before concluding your PR is stuck. Poll in
a background task, and never claim the build is verified when it hasn't run.

## Measurement

**Summed RSS overstates savings.** Shared library pages are counted once per process, so removing
a duplicate frees its *private* memory, not its RSS. Measured example: four MCP shims summed to
882 MB RSS but 643 MB PSS / 564 MB private, and per-process private ranged 54 MB down to 2 MB —
which completely changes which duplicate is worth removing. Quote private when arguing "removing
this saves N MB".

**A large mapping is often not resident.** SysV/tmpfs segments are lazily populated. Xvfb's
506 MB framebuffer shows `Rss: 0` in `/proc/<pid>/smaps`. Check before calling anything a leak.

**`/proc/meminfo` and `free` show host figures** — there is no memory cgroup namespace here.
Never attribute those totals to the add-on.

**`rtk` filters some command output.** For a complete listing, redirect to a file and read that
(`ps ... > $SP/ps.txt`), or use `rtk proxy <cmd>`.

## Passing values into base-image services

The plumbing has four stages. `scripts/env_trace.sh <VAR> <process>` walks all four and tells
you which one drops the value — use it rather than reasoning about this from memory.

1. `/data/options.json` — the user's saved options.
2. **Injected export block** — `.templates/00-global_var.sh` writes a literal
   `export <option>='<value>'` block into *every* service `run` script, using the option name
   **verbatim**. So `max_resolution` *is* injected; it just isn't a name any service reads.
   `MAX_RES` would be both injected and read.
3. `container_environment` — s6's envdir, read **only** by services whose shebang is
   `#!/usr/bin/with-contenv`.
4. The running process — the only stage that decides behaviour.

**Name the option exactly as the env var the service reads** (uppercase), the way `DRINODE`,
`KEYBOARD` and `TZ` already do. Verified live: `DRINODE` appears as `export DRINODE=…` in all 16
service run scripts including `svc-xorg`, and Xvfb runs with `-vfbdevice /dev/dri/renderD128`.

**Two consequences that are easy to get wrong:**

- `00-global_var.sh` is cont-init **00**. Any cont-init script numbered higher runs *after* the
  injection, so it cannot change what a service will see through stage 2.
- LSIO's `svc-xorg` starts `#!/usr/bin/env bashio`, **not** `with-contenv`, so it never reads
  stage 3 at all. Writing `container_environment` for it is a silent no-op — that shipped: the
  file was written 6 seconds before Xvfb started, and Xvfb still came up at the base-image
  default.

**Renaming an option to match a base-image env var moves validation out of your script and into
the schema.** `00-global_var.sh` exports empty strings (only objects/arrays/nulls are dropped),
and base-image scripts typically test `${VAR+x}` — *set*-ness, not emptiness. So an empty
`MAX_RES` becomes `Xvfb -screen 0 "x24"` and the X server does not start. If you make this move,
constrain the value in `config.yaml` (`match(^[0-9]{1,5}x[0-9]{1,5}$)?`) in the same commit, or
keep a guard script.

**Open question, unresolved:** what Supervisor does with a stored `options.json` key that no
longer exists in the new schema — error, warn, or silently drop. This decides whether renaming an
option is safe on upgrade. The `monica` add-on shipped exactly such a rename
(`MEILISEARCH_KEY` → `meilisearch_key`) with no migration, which is weak evidence it is
tolerated. The base image has an `init-migrations` oneshot reading `/migrations` if a migration
is needed. Confirm before renaming a shipped option.

Whichever mechanism you use, verify the service actually received it:

```bash
tr '\0' '\n' < /proc/<pid>/environ | grep <VAR>
```

**`cont-init.d` runs as root before s6 services start** — that part is true and is the right
place for filesystem and permission setup.

**Anything needing an X display must not run in `cont-init.d`** — Xvfb isn't up yet. Put it in
the openbox autostart. (ANGLE's OpenGL backend, for instance, fails with "Could not open the
default X display".)

## Writing into an app's own config

**A field your cont-init script writes may also be user-editable in the app's UI.** An
unconditional `UPDATE`/overwrite on every boot silently erases whatever the user added there,
and containers are recreated on restart so it re-erases forever (calibre-web
`config_reverse_proxy_trusted_ips`, #3004 — flagged by two review bots, fixed in #3010).
Prepend/merge with an idempotence guard instead of assigning.

**Prefer values that are constant across boots.** The add-on's own IP changes every restart,
so injecting it forces a rewrite-every-boot design plus stale-entry cleanup (a stale trusted IP
can be handed to a *different* add-on later). Trusting the whole supervisor range
`172.30.32.0/23` is constant, written once. For dual-stack listeners the IPv4 form never
matches IPv4-mapped addresses — also list the mapped form (`::ffff:172.30.32.0/119`).

Constant is not free when the value gates **authentication**: trusting the whole range means any
add-on on the supervisor network can send the auth header and impersonate a user. #3010 shipped
that as an explicit, stated trade-off with the maintainer's sign-off. State the blast radius in
the PR body and get the maintainer's call before widening trust — never present it as a neutral
simplification.

## Shell and bashio

**`bashio::config` for lists**: `while read ... < <(bashio::config ...)` silently yields an empty
list under errexit — bashio's internals return non-zero and process substitution inherits the
failure. Capture with `$(...)` first, then feed a here-string.

**Scripts shared by symlink**: `80-configuration.sh` and friends are shared with the webtop
add-ons. Put add-on-specific logic in a new numbered script instead of editing them.

**`grep -E '^…$'` anchors per line.** A multi-line config value passes validation on its first
line and is then used verbatim. Use bash's `[[ =~ ]]`, which anchors the whole string.

## Dockerfile and architecture

**Prefer `BUILD_ARCH` over `TARGETARCH`** — the repo's builder passes `BUILD_ARCH` explicitly,
while `TARGETARCH` is BuildKit-provided and may or may not be populated.

Either way the variable must be declared with `ARG <NAME>` **in the build stage that uses it**;
without that it expands empty, the guard never matches, and the block silently does nothing —
which is the same dead-`if` failure described just below, and the usual cause of it.

**Verify a guarded block actually ran** rather than assuming. Check whether its payload exists in
the running image (`command -v <tool>`), and cross-check `/var/log/apt/history.log` for the
matching `apt-get install` line. An `if` block whose condition never matched leaves no trace and
no error — one such block sat dead for weeks while appearing to guarantee driver verification.

**Don't test for distro-specific filenames.** A guard on
`/usr/share/vulkan/icd.d/intel_icd.x86_64.json` named a file Debian does not ship (it installs
`intel_icd.json`), so fixing the arch variable alone would have turned dead code into a failing
build.

## Versioning

**`X.Y.Z.N`, never `X.Y.Z-N`.** A hyphen parses as a semver pre-release, which Supervisor treats
as *older* than `X.Y.Z` — the update is never offered.

Date-based versions (`2026.08.03`) are common here. Check whether master has already moved to the
version you were about to use.

## Chromium / Electron under Xvfb

**Xvfb offers only indirect/software GLX**, so Chromium probes it, fails, and falls back to CPU
rendering — the GPU process runs `--use-gl=disabled` and the renderer `--disable-gpu-compositing`.

**Passing ANGLE flags is not sufficient.** `--ozone-platform=x11 --use-gl=angle
--use-angle=gl-egl` reached Chromium's command line exactly as intended and the GPU process
*still* reported `--use-gl=disabled`, having overridden the flag after its own init failed.

**A standalone ANGLE probe proves less than it appears to.** Loading Claude Desktop's bundled
`libEGL.so`, initializing the OpenGL backend and reading back
`ANGLE (Intel, Mesa Intel(R) Graphics (ADL-N), OpenGL 4.6)` proves the driver and device work —
not that Chromium's GPU process, sandbox, dmabuf import and X11 presentation path work. Codex
flagged this distinction during review and was right.

`--use-angle=gles-egl` is rejected outright by Mesa ("Intel or NVIDIA OpenGL ES drivers are not
supported").

**`--disable-dev-shm-usage`** is a workaround for Docker's 64 MB default `/dev/shm`. Home
Assistant **ignores** the add-on's `shm_size`, so the real size varies per install — it was 7.7 GB
on one host. Detect at runtime rather than assuming either way; keep the flag when the size
cannot be determined, because the crash it prevents is worse than its overhead.

## CI and review bots

**What CI actually gates** — checked against the workflows, because assuming costs a cycle.

All three hard gates below are matrixed over `check-addon-changes.outputs.changedAddons` and
`if:`-skipped when it is `[]`, so a PR that touches no add-on directory (docs, `.github/`,
`.claude/`) shows them as *skipping*, not passing — do not read that as a green build.

- **CHANGELOG updated** — hard gate (`onpr_check-pr.yaml` exits 1 without it).
- **HA add-on linter** — hard gate: `frenck/action-addon-linter` in `onpr_check-pr.yaml` has no
  `continue-on-error`, so a config.yaml schema error fails the PR.
- **Add-on image build** — hard gate, and slow; one run took ~3 h.
- **Weekly super-linter** — `lint.yml` runs with `continue-on-error: true` at both call sites, so
  it *cannot* fail a PR. Fix real findings anyway, but do not treat it as a blocker.
- **Version bump** — no workflow checks it. It is repo convention, and required for Supervisor to
  offer the rebuild, but it will not fail CI.

**"Merged" is not "on master".** The push builder's revert-on-failure job reverts the merge
commit when its prebuild step fails — including failures unrelated to your diff. A seerr fix
merged at 05:15 and was reverted one minute later because `EndBug/add-and-commit`'s floating
`v11` tag had moved to a broken release (#2993, reapplied verbatim in #2997). After merge,
`git fetch origin master` first — the remote-tracking ref is stale otherwise and would "confirm"
against pre-merge state — then check that `git diff origin/master -- <the paths you touched>` is
empty before declaring done. Scope it to your paths: master moves under you, so whole-tree
equality fails on unrelated commits. Ancestry is not the check either — this repo squash-merges,
so a merged PR head is never an ancestor of `master` (verified on #3010, whose fix is live), and
a revert leaves the original commit an ancestor anyway.

**CI rewrites your shell scripts.** `lint.yml` runs `shfmt -w -i 4 -ci -bn -sr` over every `*.sh`
and `run`, plus a `chmod +x` pass, on schedule. Repo-wide reformatting commits land on master
without your involvement — another reason a shared checkout goes stale mid-task.

**Reviewers**: CodeRabbit (deepest — often runs scripts to prove a claim; reviews ~9 minutes
after the PR opens, or on `@coderabbitai review`), chatgpt-codex-connector, Copilot, Codacy.

**Codacy `action_required` is this repo's normal state.** Other open PRs show the same. It
exposes no annotations via the API, so its findings are only visible in the maintainer's Codacy
account. Note it and move on rather than guessing.

**Resolving a review thread requires GraphQL** (`resolveReviewThread`); the REST API cannot do it.
`scripts/pr_review.sh` wraps fetch / reply / resolve.

**Most CHANGELOG heading dates are ISO, whatever the bots' defaults say.** Match the format
already in the add-on's file — a `DD-MM-YYYY` file stays `DD-MM-YYYY`. Where you have no
precedent, ISO is the house style: as of 2026-08-25, `## <version> (YYYY-MM-DD)` accounts for
7705 dated headings against 363 in `DD-MM-YYYY`, and the newest entry is ISO in 125 of 135
add-ons. Copilot flags an ISO file that gets a `DD-MM-YYYY` entry (#3019). `DD-MM-YYYY` is not
invented — it is what `onpush_builder.yaml` writes with `date '+%d-%m-%Y'` when it has to insert
a heading you forgot, and what the addons_updater bot writes when its `date_iso8601` option is
off (`99-run.sh`; it is on in production here) — but neither is a reason to write it yourself.
The builder's duplicate check is `grep -q "^## ${version} ("` — an unescaped BRE, so the dots in
a version match any character, and it does not look at the date at all. Either way an ISO heading
you wrote yourself still suppresses the bot's insertion.

**The repo's `.markdownlint.yaml` does not disable MD022/MD032**, so a CHANGELOG will show
dozens of pre-existing heading/list findings. They are noise because lint is `continue-on-error`,
not because the config exempts them — don't cite the config as a reason to ignore a finding.

**Separate new lint findings from pre-existing ones** by linting the same file at `origin/master`
and diffing the result sets — otherwise you chase warnings that were already there.
`scripts/validate.sh --vs-master` does this.
