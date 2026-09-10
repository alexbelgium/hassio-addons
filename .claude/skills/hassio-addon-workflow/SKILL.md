---
name: hassio-addon-workflow
description: >-
  Workflow for alexbelgium/hassio-addons Home Assistant add-on work: diagnose with real
  measurements, independent Codex review, implement, open a PR, resolve CodeRabbit / Copilot /
  Codex bot review comments, verify in production. Use for any task touching an add-on in this
  repo — bugs, RAM/CPU/performance tuning, Dockerfile, config.yaml, build.json,
  updater.json, cont-init.d, services.d or s6 changes, version and CHANGELOG bumps, a failing
  add-on CI check, opening or iterating PRs — and, on an add-on task, when asked to "check with
  codex", "verify with chatgpt", or resolve bot comments. Cheap for small asks: a light path skips
  the heavy steps.
---

# Home Assistant add-on workflow

**Answer style.** Chat replies are terse — no pleasantries, tool-call narration, decorative tables,
emoji or dumped logs; quote the shortest decisive line and don't re-print what is already in
context. Telegraphic fragments are fine *there*. Two things outrank brevity, because dropping a
word from either changes the meaning rather than shortening it: never compress uncertainty markers
("likely", "assumed", "not verified"), negations, numbers, units, technical terms, code or error
strings — step 9's Verified/Checked/Assumed distinction wins every time; and write full prose
wherever a fragment could be read two ways — security warnings, irreversible-action confirmations,
multi-step sequences, and everything persisted (commits, CHANGELOG entries, PR bodies, review-thread
replies, the step 10 report).

Triage first, then one of two paths:

- **Light** — typo/doc fixes, CHANGELOG edits, version bumps, one-file edits at ladder levels
  1-3 (below), simple questions: scope → implement → validate (step 4) → PR (version bump +
  CHANGELOG still required) → resolve bot comments.
- **Full loop** — performance/RAM/CPU work, diagnosis, anything changing a shipped default,
  ladder levels 4-6, or an explicit Codex-check request: scope → measure → plan → Codex reviews
  the plan → implement → simplify → Codex reviews the code → **simplify again** → PR → resolve
  comments → verify in production → report.

Escalate mid-flight if a light task grows — touches a default, needs a new script or service, or
reveals a deeper problem.

**Standing rule:** ship the simplest solution that works, and build it out of what already
exists — a `.templates/` module, an existing cont-init script, the pattern a sibling add-on
already uses for the same problem. 120+ add-ons are maintained by one person: a homogeneous repo
where every add-on solves a problem the same way is worth more than a locally nicer bespoke
design. Prefer reusing or extending over adding a parallel implementation, and when you must add
something new, spell it the way the rest of the repo spells it (naming, option names, script
numbering, file layout). Complexity is bought only by a **measurement** showing a concrete,
user-visible cost on a real host — never by reasoning about hypothetical performance, and never by
reasoning about a hypothetical *host* either. A defensive branch is complexity like any other: name
the input that reaches it and the image or host where that happens, or delete it and let the case
fail visibly instead.

**Skill root.** The canonical copy lives at `.claude/skills/hassio-addon-workflow/`. Set it once;
every `scripts/…` and `references/…` path below is relative to it:

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
review (step 6), and PR-comment listing when there are more than ~5 threads (step 8): if subagents
are available, launch one to run the command and report back only the objections/findings and your
assessment of each, not the raw transcript. Otherwise redirect the output to a file and read the
parts you need.

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

Verify you're reading the right revision first — `scripts/preflight.sh` compares the checkout
against the running `$BUILD_VERSION`, which catches the usual stale branch before it costs a full
analysis pass (a version match does not prove the source is identical). Read
`references/evidence.md` before interpreting any number you did not get straight from
`measure.sh`, and for the failure modes this step exists to prevent.

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
- For every branch that exists **only to survive something going wrong**: name the image or host
  where that input arrives (the standing rule above) and go and look, before you write it.

Full loop only, before writing code: get Codex's independent read on the plan, delegated as above —
`references/codex-review.md` has the invocation and how to write the prompt.

## 4. Implement

Read the `references/traps.md` section matching what you're about to touch. It is ~18 KB and all
but one section is irrelevant to any given edit, so print the one you need rather than reading the
file — run it with no argument to list the sections:

| Touching | Run |
| --- | --- |
| an option or anything a base-image service reads | `bash "$SKILL/scripts/traps.sh" passing` |
| a file the app also writes itself | `bash "$SKILL/scripts/traps.sh" "app's own"` |
| shell, bashio, a symlinked script | `bash "$SKILL/scripts/traps.sh" bashio` |
| `Dockerfile`, `build.json`, an arch guard | `bash "$SKILL/scripts/traps.sh" dockerfile` |
| Chromium, Electron, Xvfb | `bash "$SKILL/scripts/traps.sh" chromium` |

Then validate with `scripts/validate.sh <addon> --vs-master`, and write behavioural tests for
anything with branches, targeting **the regression a reviewer described**, not just the happy
path.

## 5. Simplify

Six questions over your own diff, before anyone else reads it:

- **Level** — did the diff stay at the ladder level chosen in step 3, or creep up one?
- **Deletion** — can this be solved by deleting instead of adding?
- **Size** — is the fix bigger than the thing it fixes?
- **Reuse** — does any hunk reimplement what `.templates/`, another script in this add-on, or a
  sibling add-on already does? If a future add-on hits this problem, will it find one way to solve
  it or two? Fold near-duplicates in, or justify the divergence in the PR body.
- **Depth** — is this a special case bolted onto shared infrastructure? Fix the shared mechanism
  instead once more than one add-on hits it; generalising from a single case is how bespoke
  designs get built, so below that bar the special case is the right call.
- **Longevity** — how does this fail in three years, when the base image or upstream has moved?

The standing exception to Reuse and Depth: scripts shared by symlink with the webtop add-ons take a
new numbered script, never an edit (`references/traps.md#shell-and-bashio`). Case studies for the rest, including
what shipped when this pass was skipped: `references/simplify.md`.

## 6. Codex attacks the code, then simplify what the review added (full loop only)

Same delegated invocation, pointed at `git diff origin/master...HEAD` plus your reasoning per
hunk. Details in `references/codex-review.md`.

Then run step 5's checks again over the hunks the review changed. Adversarial review mostly argues
*for* another branch — that is what it is asked to do — so accepting objections tends to ratchet
the diff upward, and nothing else in the loop walks it back down. Sort each objection before you
write anything:
**"this is wrong"** is a bug and you fix it; **"this is undefended"** is a claim about some host,
and it needs the same demonstration you would demand of a measurement — is the case it defends one
you have now demonstrated, or one you have merely been told about? Taking a
correctness objection often deletes the code that made it necessary, and a fix that collapses back
to fewer lines than you started the review with is the normal outcome, not a suspicious one.

These edits land after step 4's checks already ran, so re-run them: `scripts/validate.sh <addon>
--vs-master` plus the behavioural tests, over the final diff. Deleting a branch is exactly the
kind of edit that leaves a stray `fi` behind.

## 7. Open the PR

Three hard gates — **`CHANGELOG.md` updated**, the **HA add-on linter**
(`frenck/action-addon-linter`), and the **add-on image build** — but only on a PR that changes a
top-level `config.*`. On a PR that doesn't (docs, `.github/`, `.claude/`) they *skip*, which is not
the same as passing. Super-Linter runs on every PR and is `continue-on-error`, so it never blocks;
fix its real findings anyway. Nothing checks the version bump, so bump it yourself — Supervisor
won't offer a rebuild without one, and `CLAUDE.md` has the format. Update `README.md` if you added
options; write the CHANGELOG heading as `## <version> (<date>)`, matching the date format already
in that file — almost always ISO `YYYY-MM-DD`, see `references/traps.md#ci-and-review-bots`.

Write the body to a file, `gh pr create --body-file`: state what was measured, what changed,
**what is not verified**, and how to roll back the riskiest hunk alone.

## 8. Resolve review comments

`scripts/pr_review.sh list|status|watch <PR>` to read, `reply <PR> <COMMENT_ID> <text|@file>` and
`resolve <PR> <THREAD_ID…|--all>` to answer; run it with no arguments for the full usage. For every
comment, **reproduce the
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
to do when a fix cannot be self-verified: `references/evidence.md`. Then confirm the change
survived the merge: `git fetch origin master` first (the tracking ref is stale otherwise), then
`git diff origin/master -- <the paths you touched>` must come back empty. Ancestry is not the
check, and the builder reverts merges for reasons unrelated to your diff — both explained in
`references/traps.md#ci-and-review-bots`.

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

**Feed the skill.** When a shipped fix needed a follow-up PR, or a reviewer caught something this
skill should have, add the distilled lesson to the matching `references/` file in that follow-up
PR — one entry, with the PR numbers. That loop is what keeps this file short and the traps real.

Scripts are meant to be **run, not read** — each is cited at its point of use above; read one
only if its output surprises you.
