---
name: hassio-addon-workflow
description: >-
  Workflow for alexbelgium/hassio-addons Home Assistant add-on work: diagnose with real
  measurements, independent Codex review, implement, open a PR, resolve CodeRabbit / Copilot /
  Codex bot review comments, verify in production. Use for any task touching an add-on in this
  repo — bugs, RAM/CPU/performance tuning, Dockerfile, config.yaml, cont-init.d or s6 changes,
  version bumps, opening or iterating PRs — and when asked to "check with codex", "verify with
  chatgpt", or resolve bot comments. Cheap for small asks: a light path skips the heavy steps.
---

# Home Assistant add-on workflow

**Answer style.** Chat replies are terse: no pleasantries, no tool-call narration, no decorative
tables or emoji, no dumped logs — quote the shortest decisive line, and don't re-read or re-print
what is already in context. Fragments and dropped articles are fine. Never compressed: uncertainty
markers ("likely", "assumed", "not verified"), negations (`not`/`never`/`no`/`only`), numbers,
units, technical terms, code blocks, error strings — step 9's Verified/Checked/Assumed distinction
outranks brevity every time. Write in full prose, not fragments, for security warnings,
irreversible-action confirmations, and any multi-step sequence a fragment could make ambiguous.
Persisted text is prose too: commits, CHANGELOG entries, PR bodies, review-thread replies, the
step 10 report.

Triage first, then one of two paths:

- **Light** — typo/doc fixes, CHANGELOG edits, version bumps, one-file edits at ladder levels
  1-3 (below), simple questions: scope → implement → validate (`$SKILL/scripts/validate.sh
  <addon> --vs-master`; `$SKILL` defined below) → PR (version bump + CHANGELOG still required) →
  resolve bot comments.
- **Full loop** — performance/RAM/CPU work, diagnosis, anything changing a shipped default,
  ladder levels 4-6, or an explicit Codex-check request: scope → measure → plan → Codex reviews
  the plan → implement → simplify → Codex reviews the code → PR → resolve comments → verify in
  production → report.

Escalate mid-flight if a light task grows — touches a default, needs a new script or service, or
reveals a deeper problem.

**Standing rule:** ship the simplest solution that works, and build it out of what already
exists — a `.templates/` module, an existing cont-init script, the pattern a sibling add-on
already uses for the same problem. 120+ add-ons are maintained by one person: a homogeneous repo
where every add-on solves a problem the same way is worth more than a locally nicer bespoke
design. Prefer reusing or extending over adding a parallel implementation, and when you must add
something new, spell it the way the rest of the repo spells it (naming, option names, script
numbering, file layout). Complexity is bought only by a **measurement** showing a concrete,
user-visible cost on a real host — never by reasoning about hypothetical performance.

**Repo layout.** `alexbelgium/hassio-addons`; each add-on is a top-level directory. This skill is
checked in at `.claude/skills/hassio-addon-workflow/` (canonical copy). Set the skill root once,
then every `scripts/…` and `references/…` path below is relative to it:

```bash
SKILL="$(git rev-parse --show-toplevel)/.claude/skills/hassio-addon-workflow"
bash "$SKILL/scripts/preflight.sh"        # and likewise for the other scripts
```

**Non-negotiables:**
- Docker build cannot be tested locally (no dockerd) — CI is the only gate.
- Never `git stash` under `/data/claude` — `refs/stash` is shared across worktrees.
- Work in a worktree under `/data`, not `/tmp` (`/tmp` is noexec).

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

Look for prior art first: grep `.templates/` and the other add-ons for something that already
solves this (`grep -rl "<knob or pattern>" --exclude-dir=.git .` — search everything, not just
`*.sh`: the mechanism may live in a `Dockerfile`'s `ARG MODULES=` or an extensionless s6 `run`
file). If an add-on already handles it, the plan is "do what that one does" — say so, and say why
the existing mechanism can't be reused if you're not reusing it.

Then rank mechanisms, pick the lowest (simplest) one that solves it, and state the choice in the
plan:

1. A config value — an option, a schema constraint, an existing env var.
2. An existing knob the base image already reads (`MAX_RES`, `DRINODE`, `SELKIES_*`).
3. A few lines in an existing script, at the point that already runs.
4. A new init script.
5. A new service, wrapper, or long-running process.
6. Custom protocol code, or patching someone else's internals.

Levels 4-6 need a reason that survives being said out loud ("upstream has no knob for this, and I
checked" is one; "it felt cleaner" is not) and mean full loop.

Attack your own plan before implementing:
- What does this do on a host **unlike this one** — no GPU, small `/dev/shm`, aarch64, a VM?
- What happens on **upgrade** to someone who configured this by hand?
- What is the **blast radius** if the assumption underneath it is wrong?
- What am I **inferring** that I could instead **detect at runtime** or **record explicitly**?
  Highest-yield question here — see `references/evidence.md`'s failure-mode section.

Full loop only, before writing code: get Codex's independent read on the plan. Spawn a subagent
whose prompt includes the path `references/codex-review.md` and tells it to follow that file's
invocation, then report back only Codex's objections and an assessment of each — not the raw
transcript.

## 4. Implement

Touching a shell script, Dockerfile, or env option? Read `references/traps.md` first — skim the
headings, read the sections you're about to touch; the bashio, s6-env, arch-guard and versioning
traps are all live. (The light-path facts it holds — versioning format, CHANGELOG heading — are
already inline in step 7.) Validate with `scripts/validate.sh <addon> --vs-master`. Write
behavioural tests for anything with branches, targeting **the regression a reviewer described**,
not just the happy path.

## 5. Simplify

Before requesting review, check: did the diff stay at the ladder level chosen in step 3? Can this
be solved by deleting instead of adding? Is the fix bigger than what it fixes? How does it fail in
three years? And on reuse: does any hunk reimplement something `.templates/`, another script in
this add-on, or a sibling add-on already does — and if a future add-on hits this same problem,
will it find one way to solve it or two? Fold a near-duplicate into the existing mechanism, or
justify the divergence in the PR body — but never at the cost of an isolation rule
`references/traps.md` documents: scripts shared by symlink with the webtop add-ons take a new
numbered script, not an edit. Case studies of what happens when this check is skipped:
`references/simplify.md`.

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

Scripts are meant to be **run, not read** — each is cited at its point of use above; read one
only if its output surprises you.
