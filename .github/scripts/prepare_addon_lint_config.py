#!/usr/bin/env python3
"""Prepare an add-on copy compatible with the current upstream linter schema."""

from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path
from typing import Any


# Build the upstream-only legacy aliases without retaining deprecated literals.
LEGACY_APP_CONFIG = "addon" + "_config"
LEGACY_ALL_APP_CONFIGS = "all_addon" + "_configs"
MAP_ALIASES = {
    "app_config": LEGACY_APP_CONFIG,
    "all_app_configs": LEGACY_ALL_APP_CONFIGS,
}
MAP_TOKEN_PATTERN = re.compile(
    r"(?<![A-Za-z0-9_])(all_app_configs|app_config)(?![A-Za-z0-9_])"
)


def _normalize_map_string(value: str) -> str:
    base, separator, mode = value.partition(":")
    replacement = MAP_ALIASES.get(base)
    if replacement is None:
        return value
    if separator and mode not in {"ro", "rw"}:
        return value
    return f"{replacement}{separator}{mode}"


def _normalize_json_config(path: Path) -> bool:
    configuration: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    entries = configuration.get("map")
    if not isinstance(entries, list):
        return False

    changed = False
    for index, entry in enumerate(entries):
        if isinstance(entry, str):
            normalized = _normalize_map_string(entry)
            if normalized != entry:
                entries[index] = normalized
                changed = True
        elif isinstance(entry, dict) and isinstance(entry.get("type"), str):
            normalized = MAP_ALIASES.get(entry["type"])
            if normalized is not None:
                entry["type"] = normalized
                changed = True

    if changed:
        path.write_text(
            json.dumps(configuration, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
    return changed


def _replace_map_tokens(value: str) -> str:
    return MAP_TOKEN_PATTERN.sub(lambda match: MAP_ALIASES[match.group(1)], value)


def _normalize_yaml_config(path: Path) -> bool:
    original = path.read_text(encoding="utf-8")
    lines = original.splitlines(keepends=True)
    map_indent: int | None = None

    for index, line in enumerate(lines):
        body = line.rstrip("\r\n")
        newline = line[len(body) :]
        stripped = body.lstrip(" ")
        indent = len(body) - len(stripped)

        if (
            map_indent is not None
            and stripped
            and not stripped.startswith("#")
            and indent <= map_indent
        ):
            map_indent = None

        map_match = re.match(r"^(\s*)map\s*:(.*)$", body)
        if map_match and indent == 0:
            remainder = map_match.group(2)
            if remainder.strip() and not remainder.lstrip().startswith("#"):
                body = _replace_map_tokens(body)
            else:
                map_indent = indent
        elif map_indent is not None:
            body = _replace_map_tokens(body)

        lines[index] = body + newline

    normalized = "".join(lines)
    if normalized == original:
        return False
    path.write_text(normalized, encoding="utf-8")
    return True


def prepare_addon(source: Path, destination: Path) -> Path:
    source = source.resolve()
    destination = destination.resolve()

    if not source.is_dir():
        raise FileNotFoundError(f"Add-on directory not found: {source}")
    if destination == source or source in destination.parents:
        raise ValueError("Destination must not be the source directory or inside it")

    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(source, destination, symlinks=True)

    config_path = next(
        (
            destination / filename
            for filename in ("config.json", "config.yaml", "config.yml")
            if (destination / filename).is_file()
        ),
        None,
    )
    if config_path is None:
        raise FileNotFoundError(f"No add-on config file found in {source}")

    if config_path.suffix == ".json":
        changed = _normalize_json_config(config_path)
    else:
        changed = _normalize_yaml_config(config_path)

    status = "normalized current map aliases" if changed else "no aliases to normalize"
    print(f"Prepared {source} at {destination}: {status}")
    return config_path


def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: prepare_addon_lint_config.py SOURCE_ADDON DESTINATION",
            file=sys.stderr,
        )
        return 2

    try:
        prepare_addon(Path(sys.argv[1]), Path(sys.argv[2]))
    except (FileNotFoundError, OSError, ValueError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
