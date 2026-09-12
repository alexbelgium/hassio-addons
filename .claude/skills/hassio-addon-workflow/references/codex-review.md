# Codex review — invocation and prompt guidance

Used for step 3 (plan review) and step 6 (code review), full loop only. Codex is a genuinely
different model reading the files itself; on this workload it has repeatedly been worth the
minutes. Run it through a subagent, per SKILL.md's delegation note.

## Invocation

**Use the CLI, not the MCP tool, for prompts of this size.** The `codex` MCP tool timed out twice
on ~4 KB prompts (2026-08-03); the CLI with the same content succeeded. The MCP tool is still fine
for short questions.

`--sandbox read-only` blocks writes, not reads, and `approval_policy=never` stops it asking for
permission rather than stopping it acting — so it can still run read-only commands and often
falls back to fetching the repo from GitHub instead of reading your worktree. Paste every number
into the prompt rather than expecting it to gather them, and treat what it reports about *local*
state as unverified. `- <` feeds the prompt file on stdin. Run it in the background so you are not
blocked for the several minutes it takes (`&` here, or your harness's background-task mechanism):

```bash
codex exec --model gpt-5.6-sol --sandbox read-only --skip-git-repo-check \
    -c approval_policy='"never"' - < prompt.md > codex_out.txt 2>&1 &
```

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
- Codex's sandbox often cannot run local commands and falls back to reading GitHub, so paste the
  evidence in rather than assuming it will find it.

**Codex agrees with confident premises.** It has confirmed a wrong conclusion stated too
confidently, and separately caught a genuine methodology error in the same review. Treat its
confirmations with the same scepticism as its objections — especially about the build.

**Its objections only ever argue for more code** — it is asked what could go wrong, never whether
the branch it wants is reachable. Sort them before writing anything; SKILL.md step 6 is that pass.

**Unprompted it will never say "this is too much".** Asked outright it will, bluntly and usefully:
on PR #3061 it answered "delete all 309 lines" of a helper both its earlier reviews had passed
without comment. Expect it to reverse an earlier position when you ask it to re-examine one — a
stance it drops that easily was never strongly held, which is itself the answer.
