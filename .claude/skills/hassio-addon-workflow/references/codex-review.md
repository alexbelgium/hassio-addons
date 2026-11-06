# Codex review — invocation and prompt guidance

Used for step 3 (plan review) and step 6 (code review), full loop only. Codex is a genuinely
different model reading the files itself; on this workload it has repeatedly been worth the
minutes. Run it through a subagent, per SKILL.md's delegation note.

## Invocation

**Use the CLI, never the MCP tool.** The `codex` MCP integration is broken — it timed out twice on
~4 KB prompts (2026-08-03) while the CLI with the same content succeeded — so invoke Codex only
through `codex exec`, whatever the prompt size.

**Use `--sandbox danger-full-access`; `read-only` silently does nothing on this host.** Codex's
sandbox is bubblewrap, and bwrap cannot create namespaces on the Home Assistant host
(`bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted`, verified 2026-11-06). Under
`--sandbox read-only` every command Codex runs fails, so it reads no files — and still exits 0 with
a polite "I couldn't access the files" answer that looks like a finished review. With the sandbox
off, nothing technical stops it writing, so the prompt's **first line is mandatory**:

```text
Read-only review: do not create, modify or delete files; no git/gh write commands.
```

Run it in the **foreground** under `timeout`, and take the answer from `--output-last-message`, not
from the transcript — backgrounded runs (`&`) have come back truncated. `- <` feeds the prompt file
on stdin:

```bash
before=$(git status --porcelain)
timeout 590 codex exec --model gpt-5.6-sol --sandbox danger-full-access --skip-git-repo-check \
    -c approval_policy='"never"' --output-last-message codex_answer.md \
    - < prompt.md > codex_out.txt 2>&1
[ "$(git status --porcelain)" = "$before" ] || echo "Codex changed the worktree — inspect before trusting anything"
```

Keep `prompt.md` and the output files outside the worktree (the scratchpad), so the
`git status --porcelain` comparison only sees what Codex did.

**Check the review is real before using it.** Treat it as not done — and re-run, not summarise —
if `codex_answer.md` is empty, says it couldn't read or access files, or cites no `file:line`
from the change under review. An exit code of 0 proves none of this. Paste every number into the
prompt anyway rather than expecting it to gather them, and treat what it reports about *local*
runtime state as unverified.

## Writing the prompt

- **Plan review (step 3):** include the files to read, your measurements **with numbers**, the
  proposed changes, and explicit instructions to challenge you. Ask direct questions ("is this
  really add-on-fixable?", "give the precise flag set") rather than "review this".
- **The proportionality question, in both reviews, as a numbered question of its own:** "is this
  the simplest way possible, and what exactly would you delete?" Sketch the smaller alternative in
  the prompt and ask it to argue for that, and quote the repo's standing simplicity rule so it has
  the bar to hold you to. Ask for lines and functions to delete, not a direction.
- **Code review (step 6):** point it at `git diff origin/master...HEAD` plus the reasoning behind
  each hunk. Ask specifically what breaks: upgrade paths, hosts unlike this one, users who
  configured things by hand. Ask directly whether a simpler mechanism would achieve the same
  thing — an outside reader spots one-level-too-deep framing far more easily than the person who
  just built it.
- Codex cannot see the running add-on, only the files, so paste the measured evidence in rather
  than assuming it will find it.

**Codex agrees with confident premises.** It has confirmed a wrong conclusion stated too
confidently, and separately caught a genuine methodology error in the same review. Treat its
confirmations with the same scepticism as its objections — especially about the build.

**Its objections only ever argue for more code** — it is asked what could go wrong, never whether
the branch it wants is reachable. Sort them before writing anything; SKILL.md step 6 is that pass.

**Unprompted it will never say "this is too much".** Asked outright it will, bluntly and usefully:
on PR #3061 it answered "delete all 309 lines" of a helper both its earlier reviews had passed
without comment. Expect it to reverse an earlier position when you ask it to re-examine one — a
stance it drops that easily was never strongly held, which is itself the answer.
