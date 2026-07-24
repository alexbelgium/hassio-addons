# Execute an approved plan — tier 3

@alexbelgium reviewed an AI-written plan and approved it. Your job is to carry
that plan out and open a pull request. The plan was already accepted, so do not
re-litigate it — execute it. The only judgement left to you is whether the plan
still applies to the current source.

Read:

- `/tmp/ai-exec/plan.md` — the approved plan (root cause, the exact files and
  diff, verification, risk). This is your spec.
- `/tmp/ai-exec/issue.json` — the issue it fixes (for `Closes #<n>` and context).

## Hard limits (identical to the fix sweep — a workflow step enforces them)

1. **Never modify `.github/` or `.templates/`.** Repo-wide infrastructure.
2. **Never touch the `version` or `upstream` fields in `config.yaml`.**
3. **One add-on, one branch:** `ai-fix/<addon>-<issue-number>`.
4. **Never merge, never close the issue, never enable auto-merge.** Open the
   pull request **ready for review** — CI (`onpr_check-pr.yaml`) validates it,
   a human ships it.

## Do this in order

1. **Apply the plan.** Make exactly the edits it describes. Match surrounding
   style (bash / Dockerfile; conventions vary per add-on). Run `shellcheck` on
   any shell you change. Add a `CHANGELOG.md` entry in the add-on's format.

2. **If the plan is stale** — the source moved since it was written and the diff
   no longer applies cleanly:
   - Small drift (a line shifted, a nearby rename): adapt minimally to achieve
     the plan's stated intent, and note the deviation in the PR body.
   - Large drift (the root cause or the target code is gone or now different):
     stop. Do **not** guess a new fix. Comment on the issue explaining why the
     plan no longer applies, relabel `ai:needs-human` (see step 5), open no PR.

3. **Open the pull request, ready for review.** Body: the root cause with file
   and line, what the change does, how you verified it (or an explicit statement
   that you could not), any deviation from the plan, and `Closes #<n>`. Note that
   it was executed from an approved plan.

4. **Comment on the issue** with the root cause in plain language (the reader is
   a Home Assistant user) and the pull request link. Close with a note that this
   is automated analysis pending Alex's review.

5. **Relabel, as your last action:**
   ```
   gh issue edit <n> --remove-label ai:approved --remove-label ai:plan-pending --add-label <result>
   ```
   `<result>` is `ai:fixed` if you opened a PR, or `ai:needs-human` if the plan
   was too stale to apply (step 2). A workflow step also strips the approval
   labels afterwards and flags `ai:needs-human` if no PR resulted — treat that
   as a bug in your run, not a safety net.

Keep the change within the spirit of the approved plan. If carrying it out
honestly requires substantially more than the plan described, that is a sign the
plan was wrong — stop and relabel `ai:needs-human` rather than expanding scope.
