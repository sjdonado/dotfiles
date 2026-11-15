"""Mechanical evidence validation; no behavioral claims about the product."""

from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from check_delivery import validate as validate_record


def validate(data, revision):
    return validate_record(data, revision, "## Demo\nObserved fixture result.\n")


SCRIPT = Path(__file__).with_name("check_delivery.py")
REVISION = "current-revision"


class DeliveryEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.artifact = Path(self.directory.name) / "result.txt"
        self.artifact.write_text("Recorded runtime result\n")
        self.evidence = {
            "change_type": "functional",
            "source_revision": REVISION,
            "requirements": [{"id": "journey", "behavior": "User completes requested journey"}],
            "checks": [{
                "requirement_id": "journey", "status": "executed", "kind": "runtime",
                "entry_point": "application entry", "scenario": "complete requested journey",
                "expected": "journey completes", "observed": "journey completed",
                "command": "run-runtime-check", "artifact": str(self.artifact),
                "source_revision": REVISION,
            }],
            "demo": {
                "status": "command", "reason": "Command demonstrates observable result",
                "command": "run-demo", "artifact": str(self.artifact),
                "source_revision": REVISION,
            },
        }

    def assertRejected(self, evidence, field):
        errors = validate(evidence, REVISION)
        self.assertTrue(any(field in error for error in errors), errors)

    def test_functional_command_and_inspected_capture(self):
        self.assertEqual(validate(self.evidence, REVISION), [])
        self.evidence["demo"].update(status="capture", inspected=True)
        del self.evidence["demo"]["command"]
        self.assertEqual(validate(self.evidence, REVISION), [])

    def test_green_static_ci_does_not_cover_requested_runtime_journey(self):
        row = self.evidence["checks"][0]
        row.update(kind="static", command="lint && typecheck", observed="all CI checks green")
        self.assertRejected(self.evidence, "checks[0].kind")

    def test_missing_coverage_and_unmapped_rows(self):
        self.evidence["requirements"].append({"id": "another", "behavior": "another journey"})
        self.assertRejected(self.evidence, "missing decisive row")
        self.evidence["checks"][0]["requirement_id"] = "unknown"
        self.assertRejected(self.evidence, "no matching requirement")

    def test_unverified_check(self):
        self.evidence["checks"][0]["status"] = "unverified"
        self.assertRejected(self.evidence, "checks[0].status")

    def test_current_revision_required_at_every_level(self):
        for location in ("evidence", "check", "demo"):
            with self.subTest(location=location):
                data = deepcopy(self.evidence)
                target = data if location == "evidence" else data["checks"][0] if location == "check" else data["demo"]
                target["source_revision"] = "previous-revision"
                self.assertRejected(data, "source_revision")

    def test_missing_empty_and_directory_artifacts(self):
        empty = Path(self.directory.name) / "empty.txt"
        empty.touch()
        for path in ("", str(empty), str(empty.with_name("absent.txt")), self.directory.name):
            for location in ("check", "demo"):
                with self.subTest(path=path, location=location):
                    data = deepcopy(self.evidence)
                    target = data["checks"][0] if location == "check" else data["demo"]
                    target["artifact"] = path
                    self.assertRejected(data, ".artifact")

    def test_environment_paths_rejected_before_metadata_inspection(self):
        self.evidence["checks"][0]["artifact"] = ".env.private/result.txt"
        self.evidence["demo"]["artifact"] = ".env"
        with patch("check_delivery.Path.resolve", side_effect=AssertionError("must not inspect")):
            self.assertRejected(self.evidence, "environment-secret paths")

    def test_symlink_to_environment_path_rejected(self):
        alias = Path(self.directory.name) / "alias"
        alias.symlink_to(Path(self.directory.name) / ".env.private")
        self.evidence["demo"]["artifact"] = str(alias)
        self.assertRejected(self.evidence, "environment-secret paths")

    def test_functional_demo_must_be_present_available_and_inspected(self):
        for status in ("blocked", "not_applicable"):
            with self.subTest(status=status):
                self.evidence["demo"]["status"] = status
                self.assertRejected(self.evidence, "demo.status")
        self.evidence["demo"].update(status="capture", inspected=False)
        self.assertRejected(self.evidence, "demo.inspected")
        self.evidence["demo"]["inspected"] = 1
        self.assertRejected(self.evidence, "demo.inspected")
        del self.evidence["demo"]
        self.assertRejected(self.evidence, "demo:")

    def test_nonfunctional_needs_explanation_without_image(self):
        data = {
            "change_type": "nonfunctional", "source_revision": REVISION,
            "requirements": [], "checks": [],
            "demo": {"status": "not_applicable", "reason": "Documentation only", "source_revision": REVISION},
        }
        self.assertEqual(validate(data, REVISION), [])
        data["demo"]["reason"] = " "
        self.assertRejected(data, "demo.reason")
        data["demo"].update(reason="Documentation only", status="capture")
        self.assertRejected(data, "demo.status")
        data["requirements"] = self.evidence["requirements"]
        data["checks"] = self.evidence["checks"]
        self.assertRejected(data, "nonfunctional changes require an empty list")

    def test_duplicate_requirements_and_decisive_rows(self):
        self.evidence["requirements"] *= 2
        self.evidence["checks"] *= 2
        self.assertRejected(self.evidence, "duplicate requirement")
        self.assertRejected(self.evidence, "duplicate decisive row")

    def test_malformed_types_and_missing_text(self):
        for value in (None, [], "data", 1):
            with self.subTest(root=value):
                self.assertRejected(value, "expected object")
        for field, value in (("requirements", {}), ("checks", {}), ("demo", []),
                             ("requirements", [None]), ("checks", [False]),
                             ("change_type", [])):
            with self.subTest(field=field, value=value):
                data = deepcopy(self.evidence)
                data[field] = value
                self.assertTrue(validate(data, REVISION))
        for field in self.evidence["checks"][0]:
            with self.subTest(check_field=field):
                data = deepcopy(self.evidence)
                data["checks"][0][field] = []
                self.assertTrue(validate(data, REVISION))
        self.evidence["requirements"][0]["behavior"] = " "
        self.assertRejected(self.evidence, ".behavior")

    def run_cli(self, content):
        body = Path(self.directory.name) / "pr-body.md"
        body.write_text("## Demo\nObserved fixture result.\n")
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--source-revision", REVISION, "--body-file", str(body)],
            input=content, text=True, capture_output=True, check=False,
        )

    def test_cli_exit_status_and_commands_are_never_executed(self):
        marker = Path(self.directory.name) / "must-not-exist"
        self.evidence["checks"][0]["command"] = f"touch {marker}"
        self.evidence["demo"]["command"] = f"touch {marker}"
        result = self.run_cli(json.dumps(self.evidence))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(marker.exists())
        self.evidence["checks"][0]["kind"] = "static"
        result = self.run_cli(json.dumps(self.evidence))
        self.assertEqual(result.returncode, 1)
        self.assertIn("checks[0].kind", result.stderr)

    def test_malformed_json_has_concise_error_without_input_dump(self):
        result = self.run_cli('{"private-input-marker":')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stderr.strip(), "evidence: invalid JSON")
        self.assertNotIn("private-input-marker", result.stderr)

    def test_actual_body_requires_a_nonempty_demo_section(self):
        for body in ("## Verification\nCI passed\n", "## Demo\n\n## Limits\nNone\n", "## Demo\n   \n## Limits\nNone\n",
                     "```markdown\n## Demo\nIllustrative only\n```\n", ""):
            with self.subTest(body=body):
                self.assertTrue(validate_record(self.evidence, REVISION, body))
        self.evidence["demo"]["heading"] = "Demonstration"
        self.assertEqual(validate_record(self.evidence, REVISION, "## Demonstration\nObserved result\n"), [])

    def test_environment_body_file_is_refused_without_reading(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--source-revision", REVISION, "--body-file", ".env.private"],
            input=json.dumps(self.evidence), text=True, capture_output=True, check=False,
        )
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stderr.strip(), "pr_body: unavailable or forbidden body file")


if __name__ == "__main__":
    unittest.main()
