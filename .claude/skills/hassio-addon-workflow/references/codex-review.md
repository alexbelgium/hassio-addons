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
off, nothing technical stops it writing, and it runs with this add-on's credentials and writable
mounts — so review only this repo's own files and diffs, never untrusted content (an issue body, a
downloaded archive) that could carry a prompt injection. The prompt's **first line is mandatory**:

```text
Read-only review: do not create, modify or delete files; no git/gh write commands.
```

Run it in the **foreground** under `timeout`, and take the answer from `--output-last-message`, not
from the transcript — backgrounded runs (`&`) have come back truncated. Keep the prompt and output
files in the scratchpad (`$OUT` below), never in the worktree, and run from the worktree root:

```bash
OUT=/path/to/scratchpad                # outside the worktree
snap() { git status --porcelain; git diff HEAD; }
before=$(snap | sha256sum)
rm -f "$OUT/codex_answer.md"
timeout 590 codex exec --model gpt-5.6-sol --sandbox danger-full-access --skip-git-repo-check \
    -c approval_policy='"never"' --output-last-message "$OUT/codex_answer.md" \
    - < "$OUT/prompt.md" > "$OUT/codex_out.txt" 2>&1
echo "codex exit: $?"                  # 124 = timed out; any non-zero = no review
[ "$(snap | sha256sum)" = "$before" ] || echo "Codex changed the worktree — inspect before trusting anything"
```

The snapshot covers file contents as well as status, so an extra edit to an already-modified file
is caught. It detects writes after the fact; it does not prevent them.

**Check the review is real before using it.** Treat it as not done — and re-run, not summarise —
if the exit code is non-zero, `codex_answer.md` is missing or empty, the answer says it couldn't
read or access files, or it cites no `file:line` from the files it was asked to read. For a plan
review those are existing files; a review with no findings still has to cite what it checked, so
ask for that in the prompt. An exit code of 0 alone proves none of this.

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
- Paste the measured evidence in rather than expecting Codex to gather it, and treat anything it
  reports about live runtime state as unverified until you check it yourself.
- Ask it to cite `file:line` for every claim, including the places it checked and found nothing
  wrong — that is what the validity check above looks for.

**Codex agrees with confident premises.** It has confirmed a wrong conclusion stated too
confidently, and separately caught a genuine methodology error in the same review. Treat its
confirmations with the same scepticism as its objections — especially about the build.

**Its objections only ever argue for more code** — it is asked what could go wrong, never whether
the branch it wants is reachable. Sort them before writing anything; SKILL.md step 6 is that pass.

**Unprompted it will never say "this is too much".** Asked outright it will, bluntly and usefully:
on PR #3061 it answered "delete all 309 lines" of a helper both its earlier reviews had passed
without comment. Expect it to reverse an earlier position when you ask it to re-examine one — a
stance it drops that easily was never strongly held, which is itself the answer.
