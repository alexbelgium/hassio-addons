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

- **Light** — typo/doc fixes, CHANGELOG edits, version bumps, one-file edits at ladder levels
  1-3 (below), simple questions: scope → implement → `scripts/validate.sh <addon> --vs-master` →
  PR (version bump + CHANGELOG still required) → resolve bot comments.
- **Full loop** — performance/RAM/CPU work, diagnosis, anything changing a shipped default,
  ladder levels 4-6, or an explicit Codex-check request: scope → measure → plan → Codex reviews
  the plan → implement → simplify → Codex reviews the code → PR → resolve comments → verify in
  production → report.

Escalate mid-flight if a light task grows — touches a default, needs a new script or service, or
reveals a deeper problem.

**Standing rule:** ship the simplest solution that works. Complexity is bought only by a
**measurement** showing a concrete, user-visible cost on a real host — never by reasoning about
hypothetical performance.

**Repo layout.** `alexbelgium/hassio-addons`; each add-on is a top-level directory. This skill is
checked in at `.claude/skills/hassio-addon-workflow/` (canonical copy) — invoke scripts
repo-relative: `bash "$(git rev-parse --show-toplevel)/.claude/skills/hassio-addon-workflow/scripts/<script>.sh"`.

**Non-negotiables:**
- Docker build cannot be tested locally (no dockerd) — CI is the only gate.
- Never `git stash` under `/data/claude` — `refs/stash` is shared across worktrees.
- Work in a worktree under `/data`, not `/tmp` (`/tmp` is noexec).
- Read `references/traps.md` before implementing, on **both** paths — traps bite one-liners too.

**Delegate heavy output to a subagent.** Codex reviews and multi-thread PR triage produce output
you don't need verbatim in your own context. For Codex's plan review (step 3), Codex's code
review (step 6), and PR-comment listing when there are more than ~5 threads (step 8): launch a
subagent to run the command and report back only the objections/findings and your assessment of
each, not the raw transcript.

---

## 1. Scope

State goal, non-goals, constraints, and definition of done — two sentences, explicit. A diagnosis
ask ("why is it slow?") is not automatically a fix ask. Changing a shipped default is the user's
call, not yours — ask before implementing.

## 2. Evidence before reasoning (full loop)

Measure the running add-on rather than reasoning from source (`$BUILD_VERSION` set,
`HOME=/data/data`) — reviewers hold you to the numbers. Tool per question:

- RAM/CPU → `scripts/measure.sh` (≥20 s sample)
- "I set an option and nothing happened" → `scripts/env_trace.sh <VAR> <process>`
- Is this flag/driver/package actually present? → inspect the artifact: `/proc/<pid>/cmdline`,
  `command -v`, `/var/log/apt/history.log`

Verify you're reading the right revision first — `scripts/preflight.sh` catches a stale branch
before it costs a full analysis pass. Measurement methodology, gotchas, and real failure examples:
`references/evidence.md`.

## 3. Plan — choose the mechanism level, then Codex reviews it (full loop)

Rank mechanisms, pick the lowest (simplest) one that solves it, and state the choice in the plan:

1. A config value — an option, a schema constraint, an existing env var.
2. An existing knob the base image already reads (`MAX_RES`, `DRINODE`, `SELKIES_*`).
3. A few lines in an existing script, at the point that already runs.
4. A new init script.
5. A new service, wrapper, or long-running process.
6. Custom protocol code, or patching someone else's internals.

Levels 4-6 need a reason that survives being said out loud ("upstream has no knob for this, and I
checked" is one; "it felt cleaner" is not) and mean full loop.

Full loop only, before writing code: get Codex's independent read on the plan, delegated to a
subagent per the rule above. Invocation, prompt guidance, and the "attack your own plan"
checklist: `references/codex-review.md`.

## 4. Implement

Read `references/traps.md` first — bashio, s6-env, arch-guard and versioning traps are all live.
Validate with `scripts/validate.sh <addon> --vs-master`. Write behavioural tests for anything with
branches, targeting **the regression a reviewer described**, not just the happy path.

## 5. Simplify

Before requesting review, check: did the diff stay at the ladder level chosen in step 3? Can this
be solved by deleting instead of adding? Is the fix bigger than what it fixes? How does it fail in
three years? Case studies of what happens when this check is skipped: `references/simplify.md`.

## 6. Codex attacks the code (full loop only)

Same delegated invocation, pointed at `git diff origin/master...HEAD` plus your reasoning per
hunk. Details in `references/codex-review.md`.

## 7. Open the PR

CI gates on a PR: **`CHANGELOG.md` updated** (hard fail), the **HA add-on linter**
(`frenck/action-addon-linter`, blocking — not the weekly Super-Linter, which is non-blocking), and
the **add-on image build**. Bump `version` anyway (`X.Y.Z.N`, never `X.Y.Z-N`, see
`references/traps.md#versioning`) — Supervisor won't offer a rebuild without it. Update
`README.md` if you added options; match the CHANGELOG heading format `## X.Y (DD-MM-YYYY)`.

Write the body to a file, `gh pr create --body-file`: state what was measured, what changed,
**what is not verified**, and how to roll back the riskiest hunk alone.

## 8. Resolve review comments

`scripts/pr_review.sh list|reply|resolve|status|watch <PR>`. For every comment, **reproduce the
claim before agreeing or disagreeing** — reviewers are frequently right and occasionally
confidently wrong; a reproduction takes a minute and decides it either way. Reply with the
evidence, then resolve. **Push back when you're right**, on the thread — a resolved-but-wrong
thread is worse than an open one.

## 9. Verify before declaring done

Never blur these three: **Verified** (you ran it and observed the result), **Checked** (parses,
lints, type-checks), **Assumed** (reasoning only — name the assumption). Do not write "this should
work" — either it was exercised, or say plainly it wasn't.

Light path: verification is `validate.sh` plus CI; anything beyond that is Assumed. Full loop: CI
passing proves the build works, not that the change does anything — re-run the measurement that
motivated the work once the rebuilt add-on is running. Real "merged and inert" examples, and what
to do when a fix can't be self-verified: `references/evidence.md`.

## 10. Calibrate and report

Close against the scope from step 1, not against what you ended up doing:

```
What was asked / what shipped   — mapped to the original scope
Evidence                        — the numbers, before and after
Verified                        — observed, with how
Not verified                    — and why (e.g. no dockerd locally; CI is the gate)
Known broken / left out         — explicitly, including anything descoped
Risk + rollback                 — the riskiest hunk and how to revert it alone
```

Lead with anything that did not work — a merged PR that achieved nothing is the single most
important sentence in the report. Give confidence per claim, not one blanket number.

---

## Bundled files

| File | Use |
|---|---|
| `scripts/preflight.sh` | Tools, live-add-on check, revision-vs-running-image check. Exits 2 on mismatch |
| `scripts/measure.sh` | RAM (PSS/private) + CPU snapshot; reserved vs resident. Sample ≥20 s |
| `scripts/env_trace.sh` | Trace one env var through all four plumbing stages — for "my option did nothing" |
| `scripts/validate.sh` | Local linters + CI gates; `--vs-master` shows only findings your diff added |
| `scripts/pr_review.sh` | Fetch / reply to / resolve PR review threads; watch checks |
| `references/traps.md` | Repo-specific traps — read before implementing |
| `references/evidence.md` | Measurement methodology, host-generalization failures, merged-and-inert examples |
| `references/codex-review.md` | Codex CLI invocation, prompt guidance, plan-attack checklist |
| `references/simplify.md` | Mechanism-ladder case studies and diff self-checks |

Each script's header explains its reasoning; read the script when you use it.
