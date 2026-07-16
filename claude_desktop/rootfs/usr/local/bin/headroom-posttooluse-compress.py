#!/lsiopy/bin/python3
"""Claude Code PostToolUse hook: auto-compress large tool outputs through Headroom.

Registered in ~/.claude/settings.json by 82-claude_tools.sh (managed entry, matcher
"Bash|Grep|Glob|WebFetch"). Desktop-spawned Claude Code sessions cannot be routed
through the Headroom proxy (the Electron app pins ANTHROPIC_BASE_URL to the
production endpoint, headroom #869), so compression there used to depend on the
model voluntarily calling the headroom MCP tools. This hook makes it automatic for
every session type: when a matched tool returns a large output, the hook compresses
it with Headroom's rule-based pipeline and replaces the tool output via
hookSpecificOutput.updatedToolOutput, appending a retrieval marker. The original is
stored in Headroom's shared CCR store (SQLite at ~/.headroom/ccr_store.db — the
same store the headroom MCP server reads), so the model can always get the full
output back with mcp__headroom__headroom_retrieve.

Design constraints:
- Fail open: any error or non-compressible payload exits 0 with no output, leaving
  the tool result untouched. A hook crash must never break a session.
- Fast path first: the payload is inspected before importing headroom (~0.6 s);
  small outputs never pay the import cost.
- ML text compression (Kompress) is disabled: its model loads in the background,
  which never completes inside a short-lived hook process. The rule-based
  transforms (SmartCrusher for JSON, search/log/diff/tabular compressors) carry
  the savings on tool output anyway; plain prose passes through unchanged.
- stderr fields are never compressed — error text must reach the model verbatim
  (matching Headroom's own error-protection policy).
- File-list arrays (Glob's `filenames`, Grep's `filenames` in files_with_matches
  mode — both typed `string[]` by the CLI's own output schema) are handled
  separately from prose/JSON-blob fields: Headroom's SmartCrusher subsamples
  JSON arrays for informational dumps, which is fine for e.g. a list of sensor
  states but silently drops most paths from a file listing the model needs to
  act on. Those fields are truncated deterministically instead (keep the first
  N entries, append one marker string) so the model always sees a labeled cut
  point rather than a shorter list it might mistake for the complete result.
"""

import json
import os
import sys


def _int_env(name: str, default: str) -> int:
    try:
        return int(os.environ.get(name, default))
    except (TypeError, ValueError):
        return int(default)


MIN_CHARS = _int_env("HEADROOM_HOOK_MIN_CHARS", "4000")
MIN_SAVED_TOKENS = _int_env("HEADROOM_HOOK_MIN_SAVED_TOKENS", "50")
ARRAY_KEEP = _int_env("HEADROOM_HOOK_ARRAY_KEEP", "40")
TTL_SECONDS = 3600  # matches the headroom MCP server's session TTL
SKIP_KEYS = {"stderr"}


def self_test() -> int:
    """Exit 0 when the interpreter can import headroom (used at registration time)."""
    try:
        import headroom  # noqa: F401

        return 0
    except Exception:
        return 1


def main() -> int:
    if os.environ.get("HEADROOM_HOOK_DISABLE"):
        return 0
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    if not isinstance(payload, dict):
        return 0
    response = payload.get("tool_response")

    # Find big string/array fields before paying the headroom import cost.
    def is_string_array(value):
        return isinstance(value, list) and len(value) > ARRAY_KEEP and all(isinstance(v, str) for v in value)

    if isinstance(response, str):
        string_candidates = ["__whole__"] if len(response) >= MIN_CHARS else []
        array_candidates = []
    elif isinstance(response, dict):
        string_candidates = [
            key
            for key, value in response.items()
            if key not in SKIP_KEYS and isinstance(value, str) and len(value) >= MIN_CHARS
        ]
        array_candidates = [
            key for key, value in response.items() if key not in SKIP_KEYS and is_string_array(value)
        ]
    else:
        string_candidates = []
        array_candidates = []
    if not string_candidates and not array_candidates:
        return 0

    # Keep Kompress's cache probe away from the tmpfs-backed ~/.cache default.
    os.environ.setdefault("HF_HOME", os.path.expanduser("~/.headroom/hf"))
    from headroom import savings_ledger
    from headroom.cache.compression_store import get_compression_store
    from headroom.compress import compress

    store = None
    totals = [0, 0]  # tokens before, tokens after (only for rewritten fields)

    def shrink(text):
        nonlocal store
        result = compress(
            [{"role": "tool", "content": text}],
            protect_recent=0,
            kompress_model="disabled",
        )
        compressed = result.messages[0].get("content")
        if not isinstance(compressed, str):
            compressed = json.dumps(compressed)
        saved = result.tokens_before - result.tokens_after
        if saved < MIN_SAVED_TOKENS:
            return None
        if store is None:
            store = get_compression_store()
        hash_key = store.store(
            original=text,
            compressed=compressed,
            original_tokens=result.tokens_before,
            compressed_tokens=result.tokens_after,
            compression_strategy="posttooluse_hook",
            ttl=TTL_SECONDS,
        )
        totals[0] += result.tokens_before
        totals[1] += result.tokens_after
        return (
            f"{compressed}\n"
            f"[headroom: output compressed {result.tokens_before}->{result.tokens_after} tokens; "
            f"call mcp__headroom__headroom_retrieve with hash={hash_key} if you need the full original]"
        )

    def shrink_array(items):
        nonlocal store
        original_json = json.dumps(items)
        if len(original_json) < MIN_CHARS:
            return None
        kept = items[:ARRAY_KEEP]
        truncated_json = json.dumps(kept)
        # No ML/token-counter call needed for a plain truncation decision; a char/4
        # estimate is the same fallback Headroom's own cost estimator uses and is
        # only used here to decide eligibility and annotate the marker.
        tokens_before = max(1, len(original_json) // 4)
        tokens_after = max(1, len(truncated_json) // 4)
        if tokens_before - tokens_after < MIN_SAVED_TOKENS:
            return None
        if store is None:
            store = get_compression_store()
        hash_key = store.store(
            original=original_json,
            compressed=truncated_json,
            original_tokens=tokens_before,
            compressed_tokens=tokens_after,
            compression_strategy="posttooluse_hook_array_truncate",
            ttl=TTL_SECONDS,
        )
        totals[0] += tokens_before
        totals[1] += tokens_after
        remaining = len(items) - len(kept)
        marker = (
            f"[headroom: {remaining} more of {len(items)} entries omitted "
            f"({tokens_before}->{tokens_after} tokens); call mcp__headroom__headroom_retrieve "
            f"with hash={hash_key} for the complete list]"
        )
        return kept + [marker]

    updated = None
    if isinstance(response, str):
        updated = shrink(response)
    else:
        rewritten = dict(response)
        changed = False
        for key in string_candidates:
            new_value = shrink(rewritten[key])
            if new_value is not None:
                rewritten[key] = new_value
                changed = True
        for key in array_candidates:
            new_value = shrink_array(rewritten[key])
            if new_value is not None:
                rewritten[key] = new_value
                changed = True
        if changed:
            updated = rewritten
    if updated is None:
        return 0

    savings_ledger.record_savings_event(
        tokens_before=totals[0],
        tokens_after=totals[1],
        client="posttooluse-hook",
        source="hook",
    )
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "updatedToolOutput": updated,
            }
        },
        sys.stdout,
    )
    return 0


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        sys.exit(self_test())
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
