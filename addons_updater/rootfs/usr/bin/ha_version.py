#!/usr/bin/env python3
"""Compute a Home Assistant compliant addon version."""

# Home Assistant orders addon versions with awesomeversion. Its update
# entity hides the update whenever the two versions *can* be compared and
# the new one is not strictly newer, and it cannot order a version at all
# when the string follows no known scheme. Whatever lands in the addon
# config.yaml must therefore be recognisable and strictly greater than the
# version users already have installed.
#
# Upstream tags do not always cooperate:
#
# * "1.2.3-4" is a semver pre-release, i.e. older than "1.2.3"
# * "1.2.3+4" only differs by build metadata, which semver ignores
# * "version-bf9e0b4f" or "ubuntu-2026-06-01" follow no scheme at all
#
# This helper therefore decides what to write in config.yaml, while the raw
# upstream tag stays in updater.json: the next run keeps comparing upstream
# with upstream, so a single upstream release never triggers two addon
# updates.

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

# "5.0.0b5" -> "5.0.0.5": a pre-release marker is not a version section,
# so it is turned into one rather than left for Home Assistant to guess.
MARKER = re.compile(r"^(v?\d+(?:\.\d+)*)(?:alpha|beta|rc|a|b)(\d+)(?=$|-)")
# "1.2.3-4" -> "1.2.3.4": a numeric suffix behind a dash is a semver
# pre-release and sorts before the version it is meant to supersede.
PRERELEASE = re.compile(r"^(v?\d+(?:\.\d+)*)-(\d+(?:\.\d+)*)$")
# A version made of numbers only, e.g. "1.37" or "v2026.07.10.2".
DOTTED_NUMBER = re.compile(r"^(?P<prefix>v?)(?P<number>\d+(?:\.\d+)*)$")
# A number carrying a name, e.g. "ls256", "r0" or the bare "2026".
NAMED_NUMBER = re.compile(r"^[A-Za-z]*(\d+(?:\.\d+)*)$")
# Words holding a number that says nothing about the release.
NOT_A_NUMBER = frozenset(
    ("amd64", "arm64", "aarch64", "armv7", "armhf", "i386", "x86", "x64")
)

# Upper bound for the ".1", ".2", ... local rebuild counters.
MAX_COUNTER = 100


def normalise(version: str) -> str:
    """Rewrite the parts of a tag Home Assistant would sort wrongly."""
    version = version.strip()
    # Build metadata is ignored by semver precedence, a section is not.
    version = version.replace("+", ".")
    # In both, group 1 is the release and group 2 the number to keep.
    version = MARKER.sub(r"\1.\2", version)
    return PRERELEASE.sub(r"\1.\2", version)


def is_sortable(version: str) -> bool:
    """Return True when awesomeversion recognises the version scheme."""
    if not version:
        return False
    return AwesomeVersion(version).strategy != AwesomeVersionStrategy.UNKNOWN


def is_newer(candidate: str, current: str) -> bool:
    """Return True when Home Assistant would offer the candidate."""
    if not candidate or candidate == current:
        return False
    if not current:
        return True
    try:
        return AwesomeVersion(candidate) > AwesomeVersion(current)
    except AwesomeVersionCompareException:
        # Home Assistant shows the update when it cannot compare, and it
        # is the only way out of a version following no known scheme.
        return True


def is_acceptable(candidate: str, current: str) -> bool:
    """Return True for a version safe to write in the addon config."""
    return is_sortable(candidate) and is_newer(candidate, current)


def is_year(section: str) -> bool:
    """Return True for a section that can only be a year."""
    return len(section) == 4 and 2000 <= int(section) <= 2999


def is_date_like(number: str) -> bool:
    """Return True for "YYYY.MM.DD", with or without a counter."""
    parts = number.split(".")
    if len(parts) < 3 or not is_year(parts[0]):
        return False
    month, day = (int(part) for part in parts[1:3])
    return 1 <= month <= 12 and 1 <= day <= 31


def increment(number: str) -> str:
    """Increment the last section, keeping any zero padding."""
    parts = number.split(".")
    parts[-1] = str(int(parts[-1]) + 1).zfill(len(parts[-1]))
    return ".".join(parts)


def counters(base: str) -> Iterator[str]:
    """Yield "<base>.1", "<base>.2", ... local rebuild counters."""
    for counter in range(1, MAX_COUNTER):
        yield f"{base}.{counter}"


def skeleton(version: str) -> str:
    """Return every number of a tag, in order, as dotted sections."""
    # "v26.2-ls256" -> "v26.2.256", "nightly-2.6.1.5509-ls8" ->
    # "2.6.1.5509.8", "4.16-r0-ls94" -> "4.16.0.94". Words carrying no
    # number and anything else, a commit hash in particular, are dropped.
    numbers = []
    for word in re.split(r"[-/]", normalise(version)):
        if word.lower() in NOT_A_NUMBER:
            continue
        named = NAMED_NUMBER.match(word)
        if named:
            numbers.append(named.group(1))
    if not numbers:
        return ""
    prefix = "v" if version.startswith("v") else ""
    return prefix + ".".join(numbers)


def upstream_candidates(upstream: str) -> Iterator[str]:
    """Yield the upstream tag, then the numbers hidden in it."""
    yield normalise(upstream)
    # "v26.3-ls256" -> "v26.3.256": the numbers of a tag Home Assistant
    # cannot sort still order the addon better than one of our making.
    yield skeleton(upstream)


def local_candidates(current: str, today: date, release: str) -> Iterator[str]:
    """Yield sortable versions derived from the current addon version."""
    calver = today.strftime("%Y.%m.%d")
    normalised = normalise(current)
    dotted = DOTTED_NUMBER.match(normalised)

    # An upstream that rebuilds the release the current version was built
    # from, such as "v26.3-ls257" after "v26.3-ls256", gets a local
    # counter ("26.3.1") instead of a release it never published.
    if release and normalised.startswith(release):
        yield from counters(release)

    if dotted and is_date_like(dotted.group("number")):
        # Calendar versioned addon: move to today, then count up when
        # several upstream releases land on the same day.
        yield calver
        if dotted.group("number").count(".") > 2:
            yield dotted.group("prefix") + increment(dotted.group("number"))
        yield from counters(normalised)
    elif dotted:
        # "1.37" -> "1.38": the number already in use simply moves on,
        # unless it ends on a year, which belongs to a date the addon
        # does not choose.
        if not is_year(dotted.group("number").split(".")[-1]):
            yield dotted.group("prefix") + increment(dotted.group("number"))
        yield from counters(normalised)
    else:
        # Nothing sortable to build on, e.g. "version-bf9e0b4f": keep the
        # numbers when the version has some, else switch to calendar
        # versioning, which is ordered and never runs out of numbers.
        numbers = skeleton(normalised)
        if numbers:
            yield numbers
            yield from counters(numbers)
        yield calver
        yield from counters(calver)


def resolve(current: str, upstream: str, today: date) -> str:
    """Return the version to write in the addon configuration."""
    for candidate in upstream_candidates(upstream):
        if is_acceptable(candidate, current):
            return candidate
    for candidate in local_candidates(current, today, skeleton(upstream)):
        if is_acceptable(candidate, current):
            return candidate
    return ""


# Date the expectations below are written against.
SELFTEST_DATE = date(2026, 8, 1)

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
    # Pre-release markers become a section of their own, so that the
    # number they carry keeps ordering the addon versions.
    ("5.0.0b5-3", "5.0.0b5", "5.0.0.5"),
    ("5.0.0.5", "5.0.0b6", "5.0.0.6"),
    ("5.0.0.6", "5.0.0", "5.0.0.7"),
    ("1.2.3", "1.2.4rc2", "1.2.4.2"),
    ("1.2.3", "2.0.0beta1", "2.0.0.1"),
    ("1.2.3", "1.2.4a1-2", "1.2.4.1.2"),
    # Tags Home Assistant cannot order keep every number they carry.
    ("v26.2-ls255", "v26.3-ls256", "v26.3.256"),
    ("v26.3.256", "v26.3-ls257", "v26.3.257"),
    ("v1.67.0.8", "nightly-2.6.1.5509-ls8", "2.6.1.5509.8"),
    ("4.16.0.93", "4.16-r0-ls94", "4.16.0.94"),
    ("1.43.3.10828.315", "1.43.3.10828-00f62d37d-ls316", "1.43.3.10828.316"),
    ("2026.06.01", "ubuntu-2026-07-01", "2026.07.01"),
    ("20260729.1", "nightly-20260801", "20260801"),
    ("20260801", "nightly-20260801-2", "20260801.2"),
    # A word holding a number that is not part of the release is left out.
    ("5.3.2025.11.08", "5.3-amd64-2025-11-09", "5.3.2025.11.09"),
    # Dockerhub tags dated by the updater itself.
    ("1.2.3.2026.07.25", "1.2.3-2026-08-01", "1.2.3.2026.08.01"),
    # The same, dated the other way round: the date cannot order the
    # addon, so a local counter does.
    ("1.2.3.25.07.2026", "1.2.3-01-08-2026", "1.2.3.25.07.2026.1"),
    # Tags holding no number at all: the addon number moves on...
    ("1.37", "ubunturesolute-version-8208e985", "1.38"),
    ("1.4", "sha-2b71a1c", "1.5"),
    ("2025.12-6", "alpine-sts", "2026.08.01"),
    ("version-bf9e0b4f", "version-1a2b3c4d", "2026.08.01"),
    # ... and calendar versions count up on the same day.
    ("2026.08.01", "version-1a2b3c4d", "2026.08.01.1"),
    ("2026.08.01.1", "version-2b3c4d5e", "2026.08.01.2"),
    ("2026.07.30.2", "version-3c4d5e6f", "2026.08.01"),
    # A version dated in the future is never downgraded.
    ("2026.09.15", "version-4d5e6f70", "2026.09.15.1"),
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
    """Check the rules above against known addon version histories."""
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

    if args.selftest:
        # The expectations above are written against a fixed date, so the
        # checks keep passing whenever they are run.
        if args.today:
            return selftest(date.fromisoformat(args.today))
        return selftest(SELFTEST_DATE)

    today = date.fromisoformat(args.today) if args.today else date.today()

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
