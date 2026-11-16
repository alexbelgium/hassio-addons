# Disabled workflows

These files are kept for reference only. They live outside `.github/workflows/`,
so GitHub does not load them and they cannot be re-enabled by accident from the
Actions tab.

They are the former AI triage automation, replaced by the scheduled maintainer
routine described in `.github/prompts/maintainer-routine.md`:

- `on_issues_ai_triage.yaml`
- `daily_ai_fix.yaml`
- `on_issue_approved.yaml`
- `on_pr_coderabbit.yml`
- `on_claude_mention.yml`

To bring one back, move it into `.github/workflows/` in a reviewed pull request.
They use the `AI_PR_TOKEN` and `CLAUDE_CODE_OAUTH_TOKEN` secrets.

All of them also skip their jobs when the repository variable `AI_DISABLED`
is `true` (the old kill switch). Check that variable, and clear it or set it to
`false`, when you restore a workflow, or its jobs will stay skipped.
