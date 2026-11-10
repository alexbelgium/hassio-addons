#!/usr/bin/env python3
"""Regression tests for compact GitHub Actions build-log diagnostics."""
import importlib.util
import io
import unittest
from contextlib import redirect_stdout
from pathlib import Path

MODULE = Path(__file__).with_name("summarize_build_failure.py")
spec = importlib.util.spec_from_file_location("summarize_build_failure", MODULE)
parser = importlib.util.module_from_spec(spec)
spec.loader.exec_module(parser)


class LogDiagnosisTest(unittest.TestCase):
    """Reject numeric false positives while retaining real HTTP errors."""

    def test_unrelated_numbers_are_not_http_statuses(self):
        for line in ("ERROR: failed at line 503",
                     "ERROR: 502 bytes received",
                     "ERROR: process took 504 ms",
                     "ERROR: port 500 unavailable"):
            with self.subTest(line=line):
                self.assertEqual(parser.category([line]), "Build or setup failure (unclassified)")

    def test_http_status_context(self):
        for line, expected in (
            ("curl: (22) The requested URL returned error: 504", "HTTP 5xx"),
            ("HTTP/2 502 Bad Gateway", "HTTP 5xx"),
            ("502 Bad Gateway", "HTTP 5xx"),
            ("unexpected status from GET request: 429 Too Many Requests", "HTTP 429"),
            ("toomanyrequests: retry-after: 1s", "HTTP 429"),
        ):
            with self.subTest(line=line):
                self.assertTrue(parser.category([line]).startswith(expected))

    def test_real_error_outweighs_irrelevant_number(self):
        lines = [
            "ERROR: error at line 503 of a file",
            "curl: (22) The requested URL returned error: 504",
        ]
        with io.StringIO() as out, redirect_stdout(out):
            parser.summarize(lines, "Build attempt 1")
            result = out.getvalue()
        self.assertIn("HTTP 5xx", result)
        self.assertIn("returned error: 504", result)
        self.assertNotIn("line 503", result)


if __name__ == "__main__":
    unittest.main()
