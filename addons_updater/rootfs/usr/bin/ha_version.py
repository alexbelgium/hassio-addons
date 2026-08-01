#!/usr/bin/env python3
"""Compute a Home Assistant compliant add-on version.

Home Assistant orders add-on versions with ``awesomeversion``. Its update
entity hides the update whenever the two versions *can* be compared and
the new one is not strictly newer, and it cannot order a version at all
when the string follows no known scheme. Whatever lands in the add-on
``config.yaml`` must therefore be recognisable and strictly greater than
the version users already have installed.

Upstream tags do not always cooperate:

* ``1.2.3-4`` is a semver pre-release, i.e. *older* than ``1.2.3``;
* ``1.2.3+4`` only differs by build metadata, which semver ignores;
* ``version-bf9e0b4f`` or ``ubuntu-2026-06-01`` follow no scheme at all.

This helper therefore decides what to write in ``config.yaml``, while the
raw upstream tag stays in ``updater.json``: the next run keeps comparing
upstream with upstream, so a single upstream release never triggers two
add-on updates.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections.abc import Iterator
from datetime import date

from awesomeversion import (
    AwesomeVersion,
    AwesomeVersionCompareException,
    AwesomeVersionStrategy,
)

# "1.2.3-4" -> "1.2.3.4": a numeric suffix behind a dash is a semver
# pre-release and sorts before the version it is meant to supersede.
PRERELEASE = re.compile(r"^(v?\d+(?:\.\d+)*)-(\d+(?:\.\d+)*)$")
# A version made of numbers only, e.g. "1.37" or "v2026.07.10.2".
DOTTED_NUMBER = re.compile(r"^(?P<prefix>v?)(?P<number>\d+(?:\.\d+)*)$")
# The first dotted number inside a tag, e.g. "26.2" in "v26.2-ls255".
EMBEDDED_NUMBER = re.compile(r"\d+(?:\.\d+)+")

# Upper bound for the ".1", ".2", ... local rebuild counters.
MAX_COUNTER = 100


def normalise(version: str) -> str:
    """Rewrite the parts of a tag Home Assistant would sort wrongly."""
    version = version.strip()
    # Build metadata is ignored by semver precedence, a section is not.
    version = version.replace("+", ".")
    # Group 1 is the release, group 2 the counter behind the dash.
    return PRERELEASE.sub(r"\1.\2", version)


def is_sortable(version: str) -> bool:
    """Return True when awesomeversion recognises the version scheme."""
    if not version:
        return False
    return AwesomeVersion(version).strategy != AwesomeVersionStrategy.UNKNOWN


def is_newer(candidate: str, current: str) -> bool:
    """Return True when Home Assistant would offer *candidate*.

    A version that cannot be compared to the installed one is accepted:
    Home Assistant shows the update in that case, and it is the only way
    out for an add-on whose current version follows no known scheme.
    """
    if not candidate or candidate == current:
        return False
    if not current:
        return True
    try:
        return AwesomeVersion(candidate) > AwesomeVersion(current)
    except AwesomeVersionCompareException:
        return True


def is_acceptable(candidate: str, current: str) -> bool:
    """Return True for a version safe to write in the add-on config."""
    return is_sortable(candidate) and is_newer(candidate, current)


def is_date_like(number: str) -> bool:
    """Return True for a "YYYY.MM.DD" calendar version."""
    parts = number.split(".")
    if len(parts) != 3 or len(parts[0]) != 4:
        return False
    year, month, day = (int(part) for part in parts)
    return 2000 <= year <= 2999 and 1 <= month <= 12 and 1 <= day <= 31


def increment(number: str) -> str:
    """Increment the last section, keeping any zero padding."""
    parts = number.split(".")
    parts[-1] = str(int(parts[-1]) + 1).zfill(len(parts[-1]))
    return ".".join(parts)


def counters(base: str) -> Iterator[str]:
    """Yield "<base>.1", "<base>.2", ... local rebuild counters."""
    for counter in range(1, MAX_COUNTER):
        yield f"{base}.{counter}"


def upstream_candidates(upstream: str) -> Iterator[str]:
    """Yield the upstream tag, then the release number hidden in it."""
    normalised = normalise(upstream)
    yield normalised
    # "v26.3-ls256" -> "26.3": the upstream release number of a tag Home
    # Assistant cannot sort still beats a number of our own making.
    embedded = EMBEDDED_NUMBER.search(normalised)
    if embedded:
        yield embedded.group(0)


def local_candidates(current: str, today: date, release: str) -> Iterator[str]:
    """Yield sortable versions derived from the current add-on version.

    *release* is the upstream release number the current version was
    built from, when it is known. An upstream that rebuilds the same
    release, such as "v26.3-ls257" after "v26.3-ls256", gets a local
    counter ("26.3.1") instead of a release number it never published.
    """
    calver = today.strftime("%Y.%m.%d")
    normalised = normalise(current)
    dotted = DOTTED_NUMBER.match(normalised)

    if release and normalised.startswith(release):
        yield from counters(release)

    if dotted and is_date_like(dotted.group("number")):
        # Calendar versioned add-on: move to today, then count up when
        # several upstream releases land on the same day.
        yield calver
        yield from counters(normalised)
    elif dotted:
        # "1.37" -> "1.38": the number already in use simply moves on.
        yield dotted.group("prefix") + increment(dotted.group("number"))
        yield from counters(normalised)
    else:
        # Nothing sortable to build on, e.g. "version-bf9e0b4f": keep the
        # release number when the tag has one, else switch to calendar
        # versioning, which is ordered and never runs out of numbers.
        embedded = EMBEDDED_NUMBER.search(normalised)
        if embedded:
            yield from counters(embedded.group(0))
        yield calver
        yield from counters(calver)


def resolve(current: str, upstream: str, today: date) -> str:
    """Return the version to write in the add-on configuration."""
    for candidate in upstream_candidates(upstream):
        if is_acceptable(candidate, current):
            return candidate
    embedded = EMBEDDED_NUMBER.search(normalise(upstream))
    release = embedded.group(0) if embedded else ""
    for candidate in local_candidates(current, today, release):
        if is_acceptable(candidate, current):
            return candidate
    return ""


SELFTESTS = (
    # (current, upstream, expected)
    # Sortable upstream releases are used as they are.
    ("3.0.3", "3.0.4", "3.0.4"),
    ("v3.21.0", "v3.22.0", "v3.22.0"),
    ("2026.02.28", "2026.03.01", "2026.03.01"),
    ("1.43.1.10611", "1.43.2.10650", "1.43.2.10650"),
    # Tags Home Assistant compares as older than what is installed.
    ("1.2.3", "1.2.3-2", "1.2.3.2"),
    ("1.2.3.2", "1.2.3-3", "1.2.3.3"),
    ("1.2.3", "1.2.3+4", "1.2.3.4"),
    ("1.2.3.4", "1.2.3+5", "1.2.3.5"),
    ("1.2.4", "1.2.3", "1.2.5"),
    # Unsortable tags: the release number in the tag comes first...
    ("v26.2-ls255", "v26.3-ls256", "26.3"),
    ("26.3", "v26.3-ls257", "26.3.1"),
    ("26.3.1", "v26.3-ls258", "26.3.2"),
    ("v1.67.0.8", "nightly-2.6.0.5494-ls8", "2.6.0.5494"),
    # ... and the add-on number moves on when the tag has none.
    ("1.37", "ubunturesolute-version-8208e985", "1.38"),
    ("1.4", "sha-2b71a1c", "1.5"),
    ("2025.12-6", "alpine-sts", "2026.08.01"),
    ("version-bf9e0b4f", "version-1a2b3c4d", "2026.08.01"),
    ("ubuntu-2026-06-01", "ubuntu-2026-07-01", "2026.08.01"),
    # Dockerhub tags dated by the updater itself, which awesomeversion
    # reads as a semver pre-release and never sorts as newer.
    ("1.2.3-2026-07-25", "1.2.3-2026-08-01", "1.2.3"),
    ("1.2.3", "1.2.3-2026-08-02", "1.2.3.1"),
    ("1.2.3.1", "1.2.3-2026-08-03", "1.2.3.2"),
    # Calendar versions, including several updates on the same day.
    ("2026.07.31", "nightly-20260801", "2026.08.01"),
    ("2026.08.01", "nightly-20260801-2", "2026.08.01.1"),
    ("2026.08.01.1", "nightly-20260801-3", "2026.08.01.2"),
    # A version dated in the future is never downgraded.
    ("2026.09.15", "nightly-20260801", "2026.09.15.1"),
    # Switching between schemes, in both directions.
    ("version-bf9e0b4f", "3.0.4", "3.0.4"),
    ("3.0.4", "version-bf9e0b4f", "3.0.5"),
    # Tags holding characters that are special to sed.
    ("1.2.3", "1.2.4+build[1]", "1.2.4"),
    ("1.2.3", "release/2.0", "2.0"),
    ("2.0", "release/2.0.1", "2.0.1"),
    ("26.3", "v26.2-ls260", "26.4"),
    # No current version to build on.
    ("", "3.0.4", "3.0.4"),
    ("", "1.2.3-2", "1.2.3.2"),
    ("", "version-bf9e0b4f", "2026.08.01"),
)


def selftest(today: date) -> int:
    """Check the rules above against known add-on version histories."""
    failures = 0
    for current, upstream, expected in SELFTESTS:
        result = resolve(current, upstream, today)
        if result != expected:
            failures += 1
            print(
                f"FAIL {current!r} + {upstream!r} -> "
                f"{result!r}, expected {expected!r}",
                file=sys.stderr,
            )
    print(f"{len(SELFTESTS) - failures}/{len(SELFTESTS)} checks passed")
    return 1 if failures else 0


def main() -> int:
    """Parse the arguments and print the resulting version."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--current", default="", help="version in use")
    parser.add_argument("--upstream", default="", help="upstream tag")
    parser.add_argument("--today", default="", help="YYYY-MM-DD override")
    parser.add_argument(
        "--selftest", action="store_true", help="run the built-in checks"
    )
    args = parser.parse_args()

    today = date.fromisoformat(args.today) if args.today else date.today()

    if args.selftest:
        return selftest(today)

    if not args.upstream:
        parser.error("--upstream is required")

    version = resolve(args.current.strip(), args.upstream.strip(), today)
    if not version:
        print("no Home Assistant compliant version found", file=sys.stderr)
        return 1
    print(version)
    return 0


if __name__ == "__main__":
    sys.exit(main())
