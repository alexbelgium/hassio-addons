# AI issue triage and draft fixes

`on_issues_ai.yml` handles new or reopened issues only when
`.github/addon_submitters.json` does not map the mentioned add-on to another
maintainer.

## Processing

1. A low-cost model classifies the issue using a strict JSON schema and an
   authoritative list of existing add-on directories.
2. Straightforward questions receive an answer.
3. Reports missing essential evidence receive focused questions.
4. New add-on requests are marked for maintainer review and are never
   implemented by this automation.
5. High-confidence bugs and existing-add-on improvements opened by the
   repository owner proceed directly to Codex analysis; those opened by anyone
   else wait for a maintainer to add `ai: fix-approved`.
6. New add-on requests never enter Codex, regardless of who opens them.
7. Codex edits an isolated checkout without repository write permissions.
8. A fresh job applies and validates the patch, pushes a branch, opens a draft
   pull request, and posts the root-cause report and pull-request URL.

The validator independently rejects new top-level add-on directories and Codex
never merges pull requests. The Codex Action keeps its default authorization,
so only users with repository write access can trigger it; external issue
authors cannot run it merely by opening an issue.

## Required secret

- `OPENAI_API_KEY`: API key used for both structured triage and Codex.

## Optional secret

- `AI_PR_TOKEN`: fine-grained personal access token or GitHub App token with
  repository contents and pull-request write permissions. When absent, the
  workflow uses `GITHUB_TOKEN`. GitHub may require manual approval before CI
  runs on pull requests created with `GITHUB_TOKEN`.

## Model selection

Automated repository fixes default to `gpt-5.6` with high reasoning effort via
`.codex/config.toml`.

The `OPENAI_FIX_MODEL` repository variable remains an optional explicit
override. When it is set, the workflow passes that model directly to
`openai/codex-action`; when it is empty, Codex uses the repository default from
`.codex/config.toml`.

## Optional repository variables

- `OPENAI_TRIAGE_MODEL`: defaults to `gpt-5-mini`.
- `OPENAI_FIX_MODEL`: optional override for the default `gpt-5.6` fix model.
- `AI_MIN_CONFIDENCE`: defaults to `0.80`.
- `AI_MAX_CHANGED_FILES`: defaults to `25`.
- `AI_MAX_CHANGED_LINES`: defaults to `2000`.

The workflow creates its `ai:*` labels when it first runs.
