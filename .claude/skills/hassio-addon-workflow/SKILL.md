---
name: hassio-addon-workflow
description: >-
  End-to-end workflow for alexbelgium/hassio-addons add-on work — scope the change, diagnose
  against the live add-on with real measurements, get an independent Codex (gpt-5.6-sol) review
  of the plan, implement, have Codex review the code adversarially, open a PR, resolve the
  CodeRabbit / Copilot / Codex-connector review comments, and verify the merged result actually
  works. Use this whenever the task touches a Home Assistant add-on in this repo — fixing a bug
  or reported issue, tuning RAM, CPU or performance, editing a Dockerfile, config.yaml,
  cont-init.d script or s6 service, bumping an add-on version, or opening and iterating a PR
  against hassio-addons. Also use it when asked to "check with codex", "verify with chatgpt", or
  to resolve bot review comments on an add-on PR. Small tasks (typo fixes, version bumps,
  one-file tweaks, simple coding questions) route through a light path that skips measurement
  and Codex reviews — invoking this skill is cheap for small asks too.
---

# Home Assistant add-on workflow

Triage first, then one of two paths:

- **Light path** (small, contained tasks): scope → implement the simplest mechanism →
  validate → PR → resolve bot comments → report honestly.
- **Full loop** (diagnosis, performance, defaults, new mechanisms): scope → measure → plan →
  Codex attacks the plan → implement → simplify → Codex attacks the code → PR → resolve bot
  comments → verify in production → report with calibrated confidence.

**The standing rule on both paths:** when a simple solution and a more efficient-but-more-complex
one both work, ship the simple one. Complexity is only paid for by a **measurement** showing the
simple version has a concrete, user-visible cost on a real host — never by reasoning about
hypothetical performance. Slightly less efficient and obviously correct beats faster and harder
to review.

The disciplines below exist because each one, when skipped, produced a specific failure in this
repo — the examples throughout are real, not illustrative.

| Discipline | The failure it prevents |
|---|---|
| **Triage before you start** | Full ceremony spent on a one-line fix |
| **Scope before you work** | Solving the wrong problem, elegantly |
| **Evidence before reasoning** | Confident claims that measurement contradicts |
| **Reason adversarially** | Shipping something that only works on your host |
| **Simplify to the smallest thing that works** | 500 lines of machinery where an option would do |
| **Verify before declaring done** | "This should work" — and it doesn't |
| **Calibrate and report** | Verified and assumed presented as the same thing |

**Where things are.** The repo is `alexbelgium/hassio-addons`; each add-on is a top-level
directory (`claude_desktop/`, `birdnet-go/`, …). This skill and its scripts are checked into
the repo at `.claude/skills/hassio-addon-workflow/` — invoke scripts from the repo root, e.g.
`bash "$(git rev-parse --show-toplevel)/.claude/skills/hassio-addon-workflow/scripts/preflight.sh"`.
(In the claude_desktop add-on environment the checkout lives at `/data/claude/hassio-addons`;
a copy of this skill may also exist under `~/.claude/skills/` — the checked-in copy is
canonical.)

**Three facts to know before you touch anything**, because each is silent when violated:

- **You cannot test the Docker build** — dockerd does not start here. CI is the only gate.
- **Never `git stash` under `/data/claude`** — `refs/stash` is shared across worktrees and
  sessions, so it is not isolated even in your own worktree.
- **Work in a worktree under `/data`, not `/tmp`** (`/tmp` is `noexec`).

Repo-specific traps live in `references/traps.md`. Read it before implementing — it is the
accumulated cost of previous sessions. The repo's own `CLAUDE.md` covers structure, Dockerfile
conventions, CI and lint rules.

---

## 0. Triage — pick the path

Classify the task before doing anything else.

**Light path** — typo/doc fixes, CHANGELOG edits, version bumps, one-file small edits at
mechanism levels 1–3 (the ladder in step 3), simple coding questions. Flow: one-sentence scope →
pick the simplest mechanism → implement → `scripts/validate.sh <addon> --vs-master` → PR
(version bump + CHANGELOG still required) → resolve bot comments. Skip measurement, both Codex
reviews, and post-deploy measurement — but still label claims Verified / Checked / Assumed
honestly in the report.

**Full loop** — performance/RAM/CPU work, diagnosis ("why is X slow/broken"), anything changing
a shipped default, changes spanning several scripts or mechanisms (a version bump's
config.yaml + CHANGELOG + Dockerfile touch is still light), anything at ladder levels 4–6, or
when the user asks for a Codex check.

**Escalation rule** — if a light task grows mid-flight (touches a default, needs a new script or
service, reveals a deeper problem), stop and upgrade to the full loop rather than continuing
light.

`references/traps.md` is required reading on **both** paths — traps bite one-liners too.

## 1. Scope before you work

Write this down before generating anything. Two sentences is enough, but they must be explicit:

- **Goal** — the observable outcome, in the user's terms.
- **Non-goals** — what you are deliberately not touching. This is the load-bearing half.
- **Constraints** — what cannot change (defaults for other users, upgrade paths, arch support).
- **Definition of done** — what evidence will demonstrate success.

A diagnosis task and a fix task have different scopes. "Why is it slow?" is answered by
measurement and a written finding; it does not automatically authorize a rewrite. When the user's
ask genuinely spans several changes, list them and say which you are doing now.

Ask about defaults when the answer changes who is affected. Changing a shipped default touches
every user of a 120-add-on repo; making it opt-in touches nobody until they choose. That is the
user's call, not yours, and it is cheap to ask before implementing rather than after.

## 2. Evidence before reasoning

State no cause you have not observed. On a live add-on (`$BUILD_VERSION` set, `HOME=/data/data`)
measure the running system rather than reasoning from source — reviewers will hold you to the
numbers, and source-derived guesses are where wrong plans come from.

Pick the tool to the question:

- **"what is consuming RAM/CPU?"** → `scripts/measure.sh` (PSS and private, not summed RSS; keep
  the sample at ≥20 s — a 3 s sample measured 2.3% where 20 s measured 21.6%).
- **"I set an option and nothing happened"** → `scripts/env_trace.sh <VAR> <process>`, which
  walks all four stages of the option plumbing and names the one that dropped the value.
- **"is this flag/driver/package actually present?"** → look at the artifact itself:
  `/proc/<pid>/cmdline`, `command -v`, `/var/log/apt/history.log`.

`references/traps.md#measurement` explains why summed RSS and reserved-vs-resident both matter.

Before asserting anything, ask what would show it false, then go look:

- "This process is duplicated" → is it? `ps -ef --forest`, compare parents and start times.
- "This costs 500 MB" → is it resident? `grep Rss /proc/<pid>/smaps`.
- "This block never runs" → is its payload in the image? `command -v`, `apt` history.
- "The flag isn't set" → `tr '\0' '\n' < /proc/<pid>/cmdline`.

**Verify the revision you are reading.** `scripts/preflight.sh` compares the checkout's
`config.yaml` version against the running `$BUILD_VERSION`. A stale branch reads as completely
normal and has already cost one full analysis pass.

When you correct yourself mid-analysis, keep the correction visible in your notes and in what you
report. A retracted claim that stays retracted is worth more than one quietly dropped.

## 3. Plan, then have Codex attack it

### Choose the mechanism level first (both paths)

Rank mechanisms and start from the top — choose the level **before writing code** and state it
in the plan. Each step down costs more to write, more to review, and more to keep working across
base-image upgrades:

1. **A config value** — an option, a schema constraint, an existing env var.
2. **An existing knob** the base image already reads (`MAX_RES`, `DRINODE`, `SELKIES_*`).
3. **A few lines in an existing script**, at the point that already runs.
4. **A new init script.**
5. **A new service, wrapper, or long-running process.**
6. **Custom protocol code, or patching someone else's internals.**

Levels 4–6 automatically mean full loop, and need a reason that survives being said out loud.
"Upstream has no knob for this, and I checked" is a reason. "It felt cleaner" is not. If two
levels both solve it, the higher (simpler) level wins even when the lower one would be more
efficient — see the standing rule at the top.

### Codex review of the plan (full loop only — skip on the light path)

Write the plan around the measurements — each proposed change tied to a number — then get an
independent read **before** writing code. Codex is a genuinely different model reading the files
itself; on this workload it has repeatedly been worth the minutes.

**Use the CLI, not the MCP tool, for prompts of this size.** `mcp__codex__codex` timed out
twice on ~4 KB prompts (2026-08-03); the CLI with the same content succeeded. This overrides the
global CLAUDE.md note recommending the MCP tool — that guidance still holds for short questions.
Run it backgrounded (`--sandbox read-only` means Codex cannot run anything, so paste every number
into the prompt; `- <` feeds the prompt file on stdin):

```bash
codex exec --model gpt-5.6-sol --sandbox read-only --skip-git-repo-check \
    -c approval_policy='"never"' - < prompt.md > codex_out.txt 2>&1
```

Write the prompt to a file. Include the files to read, your measurements **with numbers**, the
proposed changes, and explicit instructions to challenge you. Ask direct questions ("is this
really add-on-fixable?", "give the precise flag set") rather than "review this". Codex's sandbox
often cannot run local commands and falls back to reading GitHub, so paste the evidence in rather
than assuming it will find it.

**Codex agrees with confident premises.** It has confirmed a wrong conclusion stated too
confidently, and separately caught a genuine methodology error in the same review. Treat its
confirmations with the same scepticism as its objections — especially about the build.

### Attack your own plan too

Before implementing, spend a moment actively trying to break it:

- What does this do on a host **unlike this one** — no GPU, small `/dev/shm`, aarch64, a VM?
- What happens on **upgrade** to someone who configured this by hand?
- What is the **blast radius** if the assumption underneath it is wrong?
- What am I **inferring** that I could instead **detect at runtime** or **record explicitly**?

That last question is the highest-yield one here; see [the recurring failure
mode](#the-failure-mode-this-loop-keeps-producing).

## 4. Implement

Read `references/traps.md` first; the bashio, s6-env, arch-guard and versioning traps are all
live and each has shipped a bug.

Validate with `scripts/validate.sh <addon> --vs-master`.

Write behavioural tests for anything with branches. Extract an embedded Python heredoc and drive
it against fixtures with stubbed env vars; stub `bashio::*` and `df` to exercise shell paths. Test
**the regression a reviewer described**, not just the happy path — a test that only covers the
case you were already thinking about adds little.

## 5. Simplify — is this the simplest thing that works?

Do this once you have something working and before you ask anyone to review it. The question is
not "is this good code" but **"what is the smallest change that makes the symptom go away, and
why isn't that enough?"** If you cannot answer the second half, the smaller change is the answer.
And restating the standing rule: obviously correct and slightly less efficient beats faster and
harder to review — efficiency only buys complexity when a measurement shows it matters.

Checks worth running against your own diff:

- **Did the diff stay at the ladder level chosen in step 3?** If it crept up a level, either
  justify that out loud or redo it at the level you chose.
- **Can this be solved by deleting instead of adding?** A flag that shouldn't be passed, a
  process that shouldn't start, a registration that shouldn't be duplicated. Removals cannot
  regress on hosts you can't test.
- **Is the fix bigger than the thing it fixes?** That is a smell, not a rule — but it usually
  means the problem was framed one level too deep.
- **How does this fail in three years**, when the base image, Electron, or upstream has moved?
  Code that reads a documented knob keeps working. Code that reaches into private internals
  does not.

The evidence from this repo is blunt:

- A rejected PR spent a **388-line TCP proxy plus a 142-line monkeypatch of a private upstream
  method** to reclaim 159 MB — placing custom transport code in the path of every API request.
  Both independent reviewers said close it rather than iterate on it.
- A ~180-line `ctypes` probe was written to decide whether to enable GPU flags. It worked
  perfectly, proved the driver was fine, and the change **still did nothing**, because the
  question it answered was not the question that mattered.
- A resolution cap shipped as a **new init script writing an s6 envdir** — the wrong mechanism
  entirely. Renaming the option to the env var the service already reads (level 1) would have
  worked, and the new script did not.

In all three cases the simpler option existed and was skipped. Being able to build the
complicated thing is not a reason to.

## 6. Codex attacks the code (full loop only)

Same invocation, pointed at `git diff origin/master...HEAD` plus the reasoning behind each hunk.
Ask specifically what breaks: upgrade paths, hosts unlike this one, users who configured things
by hand. Ask it directly whether a simpler mechanism would achieve the same thing — an outside
reader spots one-level-too-deep framing far more easily than the person who just built it.

## 7. Open the PR

What CI actually gates on a PR: **`CHANGELOG.md` updated** (hard `exit 1`), the **HA add-on
linter** (`frenck/action-addon-linter` in `onpr_check-pr.yaml`, no `continue-on-error` — a
config.yaml schema error blocks the PR), and the **add-on image build**. The non-blocking lint
is the *weekly Super-Linter*, not the PR checks — don't confuse the two. Nothing checks the
version bump — but bump it
anyway (`X.Y.Z.N`, never `X.Y.Z-N`, see `references/traps.md#versioning`), because Supervisor will
not offer a rebuild without it, and update `README.md` if you added options. Match the existing
CHANGELOG heading format, `## X.Y (DD-MM-YYYY)`.

Write the body to a file and use `gh pr create --body-file`. State what was measured, what
changed, **what is not verified**, and how to roll back the riskiest hunk on its own.

## 8. Resolve review comments

`scripts/pr_review.sh list|reply|resolve|status|watch <PR>`.

For every comment, **reproduce the claim before agreeing or disagreeing.** A CodeRabbit finding
that `grep -E '^…$'` anchors per line — letting a multi-line value pass validation — was real and
provable in one command. A finding that a changelog heading needed a blank line was a false
positive against this repo's `.markdownlint.yaml`.

Reply with the evidence, then resolve the thread. **Push back when you are right**, on the thread,
so the maintainer can overrule you — a resolved-but-wrong thread is worse than an open one.
Equally, when a reviewer is right, fix the cause rather than papering over the symptom.

## 9. Verify before declaring done

Do not write "this should work". Either it was exercised, or say plainly that it wasn't.

On the light path, verification is `validate.sh` plus CI — anything beyond that is **Assumed**,
and the report must say so plainly.

Distinguish three states and never let them blur:

- **Verified** — you ran it and observed the result.
- **Checked but not exercised** — it parses, lints, type-checks.
- **Assumed** — reasoning only. Name the assumption.

**CI passing and the PR merging prove the build works, not that the change does anything.** Once
the rebuilt add-on is running, re-run the measurement that motivated the work. Both changes in the
session that produced this skill passed CI, merged, and were **inert**:

- The Xvfb resolution cap wrote its env file correctly and Xvfb still started at the base-image
  default — wrong env mechanism for that service.
- The GPU flags reached Chromium's command line exactly as intended, and the GPU process still
  reported `--use-gl=disabled`, having overridden them after its own init failed.

Cheap post-deploy checks: `tr '\0' '\n' < /proc/<pid>/cmdline` for flags, `/proc/<pid>/environ`
for env vars, `scripts/env_trace.sh <VAR> <process>` for the whole option plumbing, and a repeat
CPU/PSS sample against the pre-change numbers.

Some fixes cannot be self-verified. A service reads its environment only at start, so an env-var
fix is unproven until the add-on restarts — which needs the user, or `ha-cli` with their
agreement. If you cannot restart, the change is **Assumed**, not Verified, and must be reported
that way.

## 10. Calibrate and report

Close against the scope from step 1, not against what you ended up doing. Structure:

```
What was asked / what shipped   — mapped to the original scope
Evidence                        — the numbers, before and after
Verified                        — observed, with how
Not verified                    — and why (e.g. no dockerd locally; CI is the gate)
Known broken / left out         — explicitly, including anything descoped
Risk + rollback                 — the riskiest hunk and how to revert it alone
```

Lead with anything that did not work. A merged PR that achieved nothing is the single most
important sentence in the report, and it must not appear after the summary of what went well.

Give confidence per claim, not one blanket number, and make it mean something: "measured", "CI
verified", "unverified — reasoning only". If a number came from one host, say so.

---

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

## Token efficiency

`rtk` wraps commands via hook automatically. Compress large structured output you will re-read
with `mcp__headroom__headroom_compress` (skip error/stack output). Use
`mcp__tokensave__tokensave_context` for code exploration. Redirect big output to a file and read
only what you need, and poll CI in a **background** task rather than blocking.

## Bundled files

| File | Use |
|---|---|
| `scripts/preflight.sh` | Tools, live-add-on check, revision-vs-running-image check. Exits 2 on mismatch |
| `scripts/measure.sh` | RAM (PSS/private) + CPU snapshot; reserved vs resident. Sample ≥20 s |
| `scripts/env_trace.sh` | Trace one env var through all four plumbing stages — for "my option did nothing" |
| `scripts/validate.sh` | Local linters + CI gates; `--vs-master` shows only findings your diff added |
| `scripts/pr_review.sh` | Fetch / reply to / resolve PR review threads; watch checks |
| `references/traps.md` | Repo-specific traps — read before implementing |

Each script's header explains its reasoning; read the script when you use it.
