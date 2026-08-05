# Codex review — invocation and prompt guidance

Used for step 3 (plan review) and step 6 (code review), full loop only. Codex is a genuinely
different model reading the files itself; on this workload it has repeatedly been worth the
minutes. Delegate the invocation to a subagent (see SKILL.md's subagent-delegation note) so its
output doesn't land verbatim in your context — have the subagent return only Codex's objections
and your assessment of each.

## Invocation

**Use the CLI, not the MCP tool, for prompts of this size.** The `codex` MCP tool timed out twice
on ~4 KB prompts (2026-08-03); the CLI with the same content succeeded. The MCP tool is still fine
for short questions.

`--sandbox read-only` lets Codex read files but blocks writes and command execution, and
`approval_policy=never` means it will not be prompted for permission to run anything either — so
paste every number into the prompt rather than expecting Codex to gather it. `- <` feeds the
prompt file on stdin. Run it in the background so you are not blocked for the several minutes it
takes (`&` here, or your harness's background-task mechanism):

```bash
codex exec --model gpt-5.6-sol --sandbox read-only --skip-git-repo-check \
    -c approval_policy='"never"' - < prompt.md > codex_out.txt 2>&1 &
```

## Writing the prompt

- **Plan review (step 3):** include the files to read, your measurements **with numbers**, the
  proposed changes, and explicit instructions to challenge you. Ask direct questions ("is this
  really add-on-fixable?", "give the precise flag set") rather than "review this".
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

## Attack your own plan too (before implementing)

- What does this do on a host **unlike this one** — no GPU, small `/dev/shm`, aarch64, a VM?
- What happens on **upgrade** to someone who configured this by hand?
- What is the **blast radius** if the assumption underneath it is wrong?
- What am I **inferring** that I could instead **detect at runtime** or **record explicitly**?
  This is the highest-yield question here — see `references/evidence.md`'s failure-mode section.
