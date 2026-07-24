# Address CodeRabbit's review — one-shot

CodeRabbit reviewed an AI-authored pull request. You are checked out on that
PR's branch (`ai-fix/<addon>-<issue>`). Your job, in a **single pass**: read
CodeRabbit's feedback and either fix each actionable point or reply saying why
it doesn't apply. This runs once — CodeRabbit re-reviewing your pushed fix will
not trigger you again.

The PR number is in your prompt. Set `PR` to it.

## Gather the feedback

- Review summaries and verdicts:
  `gh pr view "$PR" --json reviews,title,body,files`
- Inline (line-level) comments — this is where CodeRabbit's concrete suggestions
  live:
  `gh api "repos/${GITHUB_REPOSITORY}/pulls/${PR}/comments" --paginate`
  Each has `path`, `line`, `body`, and an `id` (needed to reply).

Consider only comments authored by `coderabbitai[bot]`. Ignore its collapsed
"nitpick"/"outside diff" noise unless the point is real.

## Hard limits (a workflow step enforces the first)

1. **Never modify `.github/` or `.templates/`.** Repo-wide infrastructure.
2. **Never touch the `version` or `upstream` fields in `config.yaml`.**
3. **Stay within this PR's scope and branch.** Do not open a new PR, do not
   touch other add-ons, do not merge, do not mark ready/draft.

## For each actionable comment

- **Fix it** when it's a real correctness, safety, or clarity improvement within
  scope: make the minimal edit, run `shellcheck` on any shell you change, and if
  behaviour changed update the add-on's `CHANGELOG.md` entry.
- **Decline it** when it's wrong, out of scope, or a style nit that fights the
  add-on's conventions: reply to that specific comment with one sentence of
  reasoning:
  `gh api "repos/${GITHUB_REPOSITORY}/pulls/${PR}/comments/<id>/replies" -f body='...'`

## Finish

- If you changed anything: stage, commit with a short message
  (`fix: address CodeRabbit review`), and push to the PR branch
  (`git push origin HEAD`).
- Post one summary comment on the PR (`gh pr comment "$PR" --body '...'`) listing
  what you fixed and what you deliberately left, in plain language. End with a
  note that this is automated and pending @alexbelgium's review.
- If nothing was actionable, post a one-line comment saying so and stop. Do not
  invent changes to look busy.
