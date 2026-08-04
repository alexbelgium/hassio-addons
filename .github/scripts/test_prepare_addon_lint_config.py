#!/usr/bin/env python3
"""Tests for the add-on linter map-name compatibility normalizer."""

from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).with_name("prepare_addon_lint_config.py")
SPEC = importlib.util.spec_from_file_location("prepare_addon_lint_config", SCRIPT_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Unable to load {SCRIPT_PATH}")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class PrepareAddonLintConfigTest(unittest.TestCase):
    def test_yaml_map_aliases_are_normalized_only_inside_map(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "source"
            destination = root / "destination"
            source.mkdir()
            original = """name: Fixture
version: \"1.0.0\"
slug: fixture
description: app_config remains documentation here
arch:
  - amd64
map:
  - app_config:rw
  - all_app_configs:ro
  - app_config:rw
  - type: app_config
    read_only: false
options:
  note: all_app_configs remains here too
"""
            (source / "config.yaml").write_text(original, encoding="utf-8")

            MODULE.prepare_addon(source, destination)

            normalized = (destination / "config.yaml").read_text(encoding="utf-8")
            self.assertIn("description: app_config remains documentation here", normalized)
            self.assertIn("note: all_app_configs remains here too", normalized)
            self.assertIn("- app_config:rw", normalized)
            self.assertIn("- all_app_configs:ro", normalized)
            self.assertIn("- type: app_config", normalized)
            self.assertNotIn("- app_config:rw", normalized)
            self.assertEqual(
                (source / "config.yaml").read_text(encoding="utf-8"), original
            )

    def test_json_map_aliases_and_modes_are_normalized(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "source"
            destination = root / "destination"
            source.mkdir()
            configuration = {
                "name": "Fixture",
                "version": "1.0.0",
                "slug": "fixture",
                "description": "app_config remains documentation here",
                "arch": ["amd64"],
                "map": [
                    "app_config:rw",
                    "all_app_configs:ro",
                    "app_config:rw",
                    {"type": "app_config", "read_only": False},
                ],
            }
            (source / "config.json").write_text(
                json.dumps(configuration), encoding="utf-8"
            )

            MODULE.prepare_addon(source, destination)

            normalized = json.loads(
                (destination / "config.json").read_text(encoding="utf-8")
            )
            self.assertEqual(
                normalized["map"],
                [
                    "app_config:rw",
                    "all_app_configs:ro",
                    "app_config:rw",
                    {"type": "app_config", "read_only": False},
                ],
            )
            self.assertEqual(
                normalized["description"],
                "app_config remains documentation here",
            )


if __name__ == "__main__":
    unittest.main()
