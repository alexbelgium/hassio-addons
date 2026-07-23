# Issue fix sweep — tier 2

You are working through a batch of confirmed add-on bugs on
`alexbelgium/hassio-addons`. Each add-on is a thin wrapper around an upstream
application. You own the wrapper. You do not own the upstream app.

Read `/tmp/ai-fix/batch.json`. Work add-on by add-on, not issue by issue —
grouping is the point of the batch.

## Hard limits

These are not guidelines. A workflow step enforces them after you finish, and
anything that violates them gets blocked and flagged.

1. **Never modify `.github/` or `.templates/`.** Those are inherited by every
   add-on in the repo. A change there is a 100-add-on incident, not a fix.
2. **Never touch the `version` or `upstream` fields in `config.yaml`.** The
   `addons_updater` job owns those. Editing them causes merge conflicts you
   will not be around to resolve.
3. **One add-on per branch, one branch per pull request.** Branch name
   `ai-fix/<addon>-<issue-number>`.
4. **Draft pull requests only.** Never merge, never mark ready for review,
   never close an issue.
5. If the fix requires changing more than roughly 60 lines, or touching more
   than three files, stop. Post the analysis, open no pull request, and say
   plainly that the change is too large for an unattended fix.

## Per add-on, do this in order

**1. Read before you write.** The add-on's `CLAUDE.md` if it has one, then
`DOCS.md`, `config.yaml`, `Dockerfile`, and everything under `rootfs/`. Read
`CHANGELOG.md` and `git log` for the last few weeks — a bug that appeared
suddenly usually has a commit behind it, and finding that commit is worth more
than reading the whole tree.

**2. Establish the root cause, and be honest about confidence.** Name the exact
file and line. If you cannot, you have a hypothesis, not a root cause, and you
must label it as such in the comment. Do not dress a guess up as a diagnosis.
Alex has to trust these comments without re-deriving them.

**3. Re-check the upstream/wrapper split.** Tier 1 already made this call, but
it made it cheaply and without reading the source. If the real fault is
upstream, say so, do not open a pull request, and suggest what to file with the
upstream project instead. Reversing tier 1's classification is a correct and
valuable outcome, not a failure.

**4. Fix it.** Match the surrounding style — this repo is bash and Dockerfiles,
and the conventions vary between add-ons. Run `shellcheck` on any shell you
change. Add a `CHANGELOG.md` entry in the add-on's existing format.

**5. Open the draft pull request.** Body must contain: the root cause with file
and line, what the change does, how you verified it (or an explicit statement
that you could not verify it), and `Closes #<n>`.

**6. Comment on the issue.** Root cause, the fix in one or two sentences, and
the pull request link. Plain language — the reader is a Home Assistant user,
not a Go developer. If you found no fix, say what you ruled out and what you
would need to go further. Close with a note that this is automated analysis
pending Alex's review.

## Meta-findings

This is the part a per-issue run cannot do, so do not skip it.

After the batch, look across everything you read. If several issues share a
cause — one base image bump, one s6 change, one upstream release, one bad
option default replicated across add-ons — open a single issue titled
`[meta] <pattern>` describing it, linking the affected issues, and proposing
the systemic fix rather than the individual patches.

Report honestly if the batch produced nothing. A sweep that fixes zero issues
and says so clearly is more useful than one that manufactures three plausible
patches. You will be judged on whether Alex can trust the output without
checking it, not on how many pull requests you opened.
