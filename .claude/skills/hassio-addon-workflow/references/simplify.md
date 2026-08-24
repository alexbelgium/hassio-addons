# Simplify — case studies

Evidence for why the mechanism ladder in SKILL.md step 3 exists, and why levels 4-6 need a reason
that survives being said out loud. In each case the simpler option existed and was skipped.
Being able to build the complicated thing is not a reason to.

- A rejected PR spent a **388-line TCP proxy plus a 142-line monkeypatch of a private upstream
  method** to reclaim 159 MB — placing custom transport code in the path of every API request.
  Both independent reviewers said close it rather than iterate on it.
- A ~180-line `ctypes` probe was written to decide whether to enable GPU flags. It worked
  perfectly, proved the driver was fine, and the change **still did nothing**, because the
  question it answered was not the question that mattered.
- A resolution cap shipped as a **new init script writing an s6 envdir** — the wrong mechanism
  entirely (ladder level 4). Renaming the option to the env var the service already reads
  (level 1) would have worked, and the new script did not.
- A calibre-web trusted-ips fix injected the add-on's **per-boot IP**, which forced a
  rewrite-every-boot design that erased user entries; preserving them then needed merge logic
  plus a state file recording what was injected (+34 lines, PR #3009 — closed unmerged). Asking
  "is there a constant that makes the rewrite unnecessary?" gave the shipped fix: trust the
  static supervisor range `172.30.32.0/23`, one idempotent statement, **net −6 lines**
  (PR #3010). Complexity spent working around a changing value is a sign to hunt for the
  constant instead.
- A `.templates/ha_entrypoint.sh` fix went to review at 25 lines of code and merged at 10. Two
  sources of the excess, and neither was caught by the loop: a **pure-bash fallback** written at
  implement time for images shipping `with-contenv` but not `s6-dumpenv` — reasoned from the two
  binaries living in different s6 packages, never demonstrated on any real image, and the case it
  defended would have degraded to the pre-fix behaviour anyway — and a **helper function plus a
  second reset** that existed only to serve that fallback. Deleting the fallback deleted all of
  it. The rest of the review's objections were correct and cost two tokens on an existing line.
  It took the maintainer asking "is this the simplest way possible?" to run the pass that step 6
  now requires.

## Checks worth running against your own diff

- **Did the diff stay at the ladder level chosen in step 3?** If it crept up a level, either
  justify that out loud or redo it at the level you chose.
- **Can this be solved by deleting instead of adding?** A flag that shouldn't be passed, a
  process that shouldn't start, a registration that shouldn't be duplicated. Deleting usually
  shrinks the regression surface — but not always: the `/dev/shm` case in
  `references/evidence.md` is a removal that reintroduced a crash loop on hosts unlike this one.
  A removal that depends on a host default still needs the same verification as an addition.
- **Is the fix bigger than the thing it fixes?** That is a smell, not a rule — but it usually
  means the problem was framed one level too deep.
- **For each defensive branch: what input reaches it, on which image or host?** Go and check,
  the way you would check a measurement. The bar is being able to **name** the case, not to
  reproduce it here: Docker's 64 MB `/dev/shm` default is documented behaviour that HA does not
  override, so the bullet above keeps that guard even though this host measured 7.7 GB. Nobody
  could name a single image shipping `with-contenv` without `s6-dumpenv`, so that fallback went.
  If you cannot name the case, delete the branch — the situation then fails the way it already
  fails today, visibly, instead of through a second path that is never exercised and silently
  rots as the base images move. Weigh the cost too: a one-flag guard against a crash you cannot
  rule out is cheap, a second code path that degrades to the pre-fix behaviour anyway is not.
  Write down in the PR body what you cut and why, so the next person does not re-add it from the
  same reasoning.
- **How does this fail in three years**, when the base image, Electron, or upstream has moved?
  Code that reads a documented knob keeps working. Code that reaches into private internals
  does not.
