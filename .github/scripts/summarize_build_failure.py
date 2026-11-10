#!/usr/bin/env python3
"""Extract compact, actionable evidence from a GitHub Actions build job log.

Heuristics only: never use these classifications to suppress a failed-build revert.
"""
import re
import sys
from urllib.parse import urlsplit

STAMP = re.compile(r"^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d[^ ]*Z?\s+")
ANSI = re.compile(r"\x1b\[[0-9;]*m")
START = re.compile(r"^##\[start-action display=Build image;id=([^\]]+)\]")
SIGNAL = re.compile(
    r"\b(?:ERROR|FATAL|ModuleNotFoundError|toomanyrequests)\b|"
    r"curl: \(\d+\)|(?:HTTP|status).*\b(?:429|5\d\d)\b|"
    r"connection reset|timed? out|no matching manifest|permission denied|"
    r"failed to (?:solve|fetch|copy|download|build)|no such file or directory|"
    r"unable to locate package|npm ERR!|Traceback \(most recent|syntax error",
    re.I,
)
STAGE = re.compile(r"^#\d+ (?:\d+(?:\.\d+)? )?\[[^]]+\] (?:RUN|COPY|FROM|load metadata).*")
URL = re.compile(r"https?://[^\s'\"<>]+")
DIGEST = re.compile(r"sha256:[a-fA-F0-9]{32,}")
# A bare 500-599 integer might be a line number, size, timing, or port.
# Only classify it as an HTTP error when it has protocol/status context.
HTTP_STATUS = re.compile(
    r"(?:\bHTTP(?:/\d+(?:\.\d+)?)?\b|\bstatus\b|\breturned error:)"
    r"[^\n]*?\b(?P<code>429|5\d\d)\b|"
    r"\b(?P<named>429 Too Many Requests|502 Bad Gateway|503 Service Unavailable|504 Gateway Time-?out)\b",
    re.I,
)
# Require protocol/response context before interpreting a number as HTTP status.
# A plain "error at line 503" must not be reported as a remote 503 outage.
HTTP_CONTEXT = r"(?:\bHTTP(?:/\d+(?:\.\d+)?)?\b|\bstatus\b)"
HTTP_429 = re.compile(
    HTTP_CONTEXT + r"[^\n]*?\b429\b|\b429\s+Too Many Requests\b|"
    r"\bcurl:\s*\(\d+\).*?\berror:\s*429\b",
    re.I,
)
HTTP_5XX = re.compile(
    HTTP_CONTEXT + r"[^\n]*?\b5\d\d\b|"
    r"\bcurl:\s*\(\d+\).*?\berror:\s*5\d\d\b|"
    r"\b5\d\d\s+(?:Internal Server Error|Bad Gateway|Service Unavailable|Gateway Timeout)\b",
    re.I,
)


def clean(raw):
    """Remove runner timestamps and ANSI formatting while preserving log text."""
    """Remove GitHub runner timestamps and ANSI escape sequences from a log line."""
    return STAMP.sub("", ANSI.sub("", raw.rstrip("\r\n"))).strip("\ufeff")


def short(raw, limit=230):
    """Trim large digests and diagnostic lines for concise issue bodies."""
    """Shorten diagnostic text while removing query strings and long digests."""
    raw = DIGEST.sub(lambda m: m.group(0)[:19] + "…", raw)
    raw = URL.sub(lambda m: m.group(0).split("?")[0], raw)
    raw = raw.replace("`", "'").strip()
    return raw[: limit - 1] + "…" if len(raw) > limit else raw


def category(errors):
    """Classify a root-error line conservatively; never control rollback."""
    joined = "\n".join(errors).lower()
    codes = [
        match.group("code") or match.group("named").split()[0]
        for error in errors
        for match in HTTP_STATUS.finditer(error)
    ]
    if "429" in codes or re.search(r"toomanyrequests|too many requests|rate.limit", joined):
        return "HTTP 429 / rate limit (suspected external)"
    if any(code.startswith("5") for code in codes) or re.search(r"bad gateway|gateway time.out", joined):
        return "HTTP 5xx / upstream availability (suspected external)"
    if re.search(r"connection reset|timed? out|temporary failure|tls handshake|refused_stream", joined):
        return "Network / timeout (suspected external)"
    if re.search(r"\b(?:401|403)\b|unauthorized|permission denied|denied: requested access", joined):
        return "Authentication / permissions (investigate)"
    if re.search(r"no matching manifest|not found|no such file|module not found|modulenotfounderror", joined):
        return "Missing image, resource or dependency (investigate)"
    return "Build or setup failure (unclassified)"


def summarize(lines, label):
    """Choose the strongest causal clue and its surrounding Docker build step."""
    """Print one likely causal error, build stage and remote host per attempt."""
    findings = []
    for i, value in enumerate(lines):
        if not (SIGNAL.search(value) or HTTP_STATUS.search(value)) or value.startswith("##[start-action"):
            continue
        # The runner also echoes shell source. Avoid diagnosing commands that
        # *mention* errors rather than the actual error emitted at runtime.
        if "echo \"::error" in value or "echo '::error" in value:
            continue
        rank = (0 if HTTP_STATUS.search(value) or re.search(r"toomanyrequests|curl: \(\d+\)|timed? out", value, re.I)
                    r"toomanyrequests|curl: \(\d+\)|timed? out", value, re.I
                )
                else 1 if re.search(r"^#\d+ .*ERROR:|^ERROR:|\bModuleNotFoundError\b", value, re.I)
                else 3 if value.startswith("##[error]") else 2)
        findings.append((rank, i, value))
    if not findings:
        print(f"- **{label}:** No matching diagnostic line; inspect linked job log")
        return
    findings.sort(key=lambda item: (item[0], item[1]))
    chosen = []
    for _, index, value in findings:
        candidate = short(value)
        if candidate not in [item[1] for item in chosen]:
            chosen.append((index, candidate, value))
        if len(chosen) == 1:
            break
    roots = [item[2] for item in chosen]
    print(f"- **{label}:** {category(roots)}")
    for index, candidate, _ in chosen:
        print(f"  - `{candidate}`")
    index = chosen[0][0]
    for value in reversed(lines[max(0, index - 200):index]):
        if STAGE.search(value):
            print(f"  - **Build step:** `{short(value, 150)}`")
            break
    hosts = sorted({urlsplit(match.group(0)).hostname or "" for root in roots
                    for match in URL.finditer(root)})
    hosts = [host for host in hosts if host]
    if hosts:
        print("  - **Remote host:** " + ", ".join(f"`{h}`" for h in hosts[:2]))


def main():
    """Parse failed image-build attempts, falling back to the whole job."""
    """Group failed image-build attempts from a downloaded GitHub Actions job log."""
    if len(sys.argv) != 2:
        raise SystemExit("Usage: summarize_build_failure.py JOB_LOG_FILE")
    with open(sys.argv[1], encoding="utf-8-sig", errors="replace") as file:
        lines = [clean(line) for line in file]
    if not any(lines):
        print("- Logs unavailable; use the full job URL")
        return
    attempts = []
    active = None
    for value in lines:
        match = START.match(value)
        if match:
            active = (match.group(1), [])
            continue
        if active is None:
            continue
        if value.startswith(f"##[end-action id={active[0]};"):
            if "outcome=failure" in value:
                attempts.append(active[1])
            active = None
        else:
            active[1].append(value)
    if attempts:
        for idx, attempt in enumerate(attempts[:2], 1):
            summarize(attempt, "Build attempt " + str(idx))
    else:
        summarize(lines, "Failed job (build attempts not confirmed)")


if __name__ == "__main__":
    main()
