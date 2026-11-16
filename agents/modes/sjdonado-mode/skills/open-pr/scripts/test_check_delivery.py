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
    return validate_record(data, revision, BODY, "fix/fixture")


SCRIPT = Path(__file__).with_name("check_delivery.py")
REVISION = "current-revision"
BODY = """## Summary
The requested journey now completes through the application entry.

## Reviewer notes
None.

## Verification
- **Executed (requested journey):** local fixture command returned the saved value.

## Demo
Run the fixture command; the saved value appears after reopening.
"""


class DeliveryEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.artifact = Path(self.directory.name) / "result.txt"
        self.artifact.write_text("Recorded runtime result\n")
        self.evidence = {
            "change_type": "functional",
            "body": {"template": "fallback"},
            "tickets": [],
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

    def repository_structure(self, headings, summary="Summary", verification="Verification"):
        template = Path(self.directory.name) / "repository-template.md"
        template.write_text("\n\n".join("## " + title for title in headings))
        return {
            "template": "repository", "template_path": str(template),
            "required_headings": headings, "summary_heading": summary,
            "verification_heading": verification,
        }

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
            "body": {"template": "fallback"},
            "tickets": [],
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

    def run_cli(self, content, body_text=BODY):
        body = Path(self.directory.name) / "pr-body.md"
        body.write_text(body_text)
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--source-revision", REVISION, "--body-file", str(body), "--branch", "fix/fixture"],
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
                self.assertTrue(validate_record(self.evidence, REVISION, body, "fix/fixture"))
        self.evidence["demo"]["heading"] = "Demonstration"
        self.evidence["body"] = self.repository_structure(["Summary", "Reviewer notes", "Verification", "Demonstration"])
        self.assertEqual(validate_record(self.evidence, REVISION, BODY.replace("## Demo", "## Demonstration"), "fix/fixture"), [])

    def test_environment_body_file_is_refused_without_reading(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--source-revision", REVISION, "--body-file", ".env.private", "--branch", "fix/fixture"],
            input=json.dumps(self.evidence), text=True, capture_output=True, check=False,
        )
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stderr.strip(), "pr_body: unavailable or forbidden body file")

    def test_delivery_cli_checks_actual_branch_and_ticket_resolution(self):
        self.evidence["tickets"] = [{"id": "DEMO-7", "tracker": "git-bug", "relation": "resolves"}]
        body = Path(self.directory.name) / "ticket-body.md"
        body.write_text(BODY + "\nResolves DEMO-7\n")
        args = [sys.executable, str(SCRIPT), "--source-revision", REVISION, "--body-file", str(body), "--branch", "fix/demo-7-work"]
        result = subprocess.run(args, input=json.dumps(self.evidence), text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        args[-1] = "fix/demo-70-work"
        self.assertEqual(subprocess.run(args, input=json.dumps(self.evidence), text=True, capture_output=True).returncode, 1)
        args[-1] = "fix/demo-7-work"
        body.write_text(BODY + "\nMentions DEMO-7\n")
        self.assertEqual(subprocess.run(args, input=json.dumps(self.evidence), text=True, capture_output=True).returncode, 1)

    def test_template_selection_is_mandatory_and_typed(self):
        for selection in (None, [], "fallback", {}, {"template": "unknown"}):
            with self.subTest(selection=selection):
                self.evidence["body"] = selection
                self.assertRejected(self.evidence, "body")
        del self.evidence["body"]
        result = self.run_cli(json.dumps(self.evidence))
        self.assertEqual(result.returncode, 1)
        self.assertIn("body: expected template selection", result.stderr)

    def test_fallback_requires_all_sections_in_order_exactly_once(self):
        for title in ("Summary", "Reviewer notes", "Verification", "Demo"):
            with self.subTest(missing=title):
                body = BODY.replace("## " + title, "## Unrelated")
                self.assertTrue(validate_record(self.evidence, REVISION, body, "fix/fixture"))
        reordered = BODY.replace("## Summary", "## Verification").replace("## Verification\n-", "## Summary\n-")
        self.assertTrue(any("out of template order" in e for e in validate_record(self.evidence, REVISION, reordered, "fix/fixture")))
        duplicate = BODY + "\n## Summary\nA second summary.\n"
        self.assertTrue(any("exactly once" in e for e in validate_record(self.evidence, REVISION, duplicate, "fix/fixture")))

    def test_comment_only_empty_and_placeholder_sections_are_not_content(self):
        original = "The requested journey now completes through the application entry."
        for value in ("", "<!-- Explain the problem. -->", "TODO", "**TBD.**", "- placeholder", "### Context\n<!-- Write the context -->"):
            with self.subTest(value=value):
                errors = validate_record(self.evidence, REVISION, BODY.replace(original, value), "fix/fixture")
                self.assertTrue(any("empty or a placeholder" in e for e in errors), errors)

    def test_fallback_asset_cannot_be_published_untouched(self):
        template = SCRIPT.parents[1] / "assets/pull_request_template.md"
        result = self.run_cli(json.dumps(self.evidence), template.read_text())
        self.assertEqual(result.returncode, 1)
        self.assertIn("pr_body", result.stderr)

    def test_verification_needs_a_labeled_observed_result(self):
        original = "- **Executed (requested journey):** local fixture command returned the saved value."
        for value in ("", "<!-- Run checks -->", "CI is green", "Static", "**Static:**", "**Executed:**", "Executed: TODO", "**Executed:** TBD", "```markdown\nExecuted: illustrative result only\n```"):
            with self.subTest(value=value):
                result = self.run_cli(json.dumps(self.evidence), BODY.replace(original, value))
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn("pr_body", result.stderr)
        for value in ("Static: local source inspection found only the intended copy change.", "- **Static:** lint returned zero errors.", "**Executed**: CLI returned the saved value."):
            with self.subTest(valid=value):
                self.assertEqual(validate_record(self.evidence, REVISION, BODY.replace(original, value), "fix/fixture"), [])

    def test_fenced_or_commented_heading_is_not_a_required_section(self):
        body = BODY.replace("## Summary", "```markdown\n## Summary\n```\n## Background")
        self.assertTrue(any("Summary" in e for e in validate_record(self.evidence, REVISION, body, "fix/fixture")))
        body = BODY.replace("## Verification", "<!--\n## Verification\n-->\n## Background")
        self.assertTrue(any("Verification" in e for e in validate_record(self.evidence, REVISION, body, "fix/fixture")))
        body = BODY + "\n<!--\n## Summary\nComment example\n-->\n```markdown\n## Demo\nFenced example\n```\n"
        self.assertEqual(validate_record(self.evidence, REVISION, body, "fix/fixture"), [])

    def test_nested_sections_keep_their_content(self):
        body = BODY.replace("The requested journey", "### Context\nThe requested journey").replace("- **Executed", "### Local check\n- **Executed")
        self.assertEqual(validate_record(self.evidence, REVISION, body, "fix/fixture"), [])
        body = BODY.replace("## Reviewer notes", "## Feature flag\nnone\n\n## Reviewer notes")
        self.assertEqual(validate_record(self.evidence, REVISION, body, "fix/fixture"), [])
        body = BODY.replace("## Summary\nThe requested journey now completes through the application entry.", "# Summary")
        errors = validate_record(self.evidence, REVISION, body, "fix/fixture")
        self.assertTrue(any("Summary' is empty" in error for error in errors), errors)

    def test_repository_structure_preserves_custom_sections_and_reads_no_template_contents(self):
        self.evidence["body"] = self.repository_structure(["Overview", "Review", "Checks", "Evidence"], "Overview", "Checks")
        self.evidence["demo"]["heading"] = "Evidence"
        body = BODY.replace("## Summary", "## Overview").replace("## Reviewer notes", "## Review").replace("## Verification", "## Checks").replace("## Demo", "## Evidence")
        with patch("check_delivery.Path.read_text", side_effect=AssertionError("template and artifact contents must not be read")):
            self.assertEqual(validate_record(self.evidence, REVISION, body, "fix/fixture"), [])
        result = self.run_cli(json.dumps(self.evidence), body)
        self.assertEqual(result.returncode, 0, result.stderr)
        del self.evidence["body"]["required_headings"][-1]
        self.assertRejected(self.evidence, "functional demo heading must be required")

    def test_nonfunctional_repository_template_can_omit_demo_but_not_verification(self):
        self.evidence.update(change_type="nonfunctional", requirements=[], checks=[])
        self.evidence["demo"] = {"status": "not_applicable", "reason": "Documentation only", "source_revision": REVISION}
        self.evidence["body"] = self.repository_structure(["Overview", "Checks"], "Overview", "Checks")
        body = "## Overview\nClarify the documented command.\n\n## Checks\n**Static:** compared the command against local help; arguments match.\n"
        self.assertEqual(validate_record(self.evidence, REVISION, body, "fix/fixture"), [])
        self.assertTrue(validate_record(self.evidence, REVISION, body.replace("## Checks", "## Notes"), "fix/fixture"))
        self.evidence["body"] = {"template": "fallback"}
        self.assertTrue(validate_record(self.evidence, REVISION, BODY.split("## Demo")[0], "fix/fixture"))

    def test_repository_structure_rejects_missing_or_malformed_contract(self):
        valid = self.repository_structure(["Summary", "Verification", "Demo"])
        variants = [
            {"required_headings": []}, {"required_headings": "Summary"},
            {"required_headings": [None]}, {"required_headings": ["Summary", " summary "]},
            {"summary_heading": ""}, {"verification_heading": "Unknown"},
            {"verification_heading": "Summary"}, {"template_path": ""},
            {"template_path": self.directory.name}, {"template_path": str(self.artifact.with_name("absent.md"))},
        ]
        for override in variants:
            with self.subTest(override=override):
                self.evidence["body"] = {**valid, **override}
                self.assertRejected(self.evidence, "body")

    def test_secret_template_paths_are_rejected_before_resolution(self):
        self.evidence.update(change_type="nonfunctional", requirements=[], checks=[])
        self.evidence["demo"] = {"status": "not_applicable", "reason": "Docs only", "source_revision": REVISION}
        self.evidence["body"] = self.repository_structure(["Summary", "Verification"])
        self.evidence["body"]["template_path"] = ".env.private/template.md"
        with patch("check_delivery.Path.resolve", side_effect=AssertionError("must reject before resolution")):
            self.assertRejected(self.evidence, "body.template_path: environment-secret")
        alias = Path(self.directory.name) / "template-link"
        alias.symlink_to(Path(self.directory.name) / ".env.template")
        self.evidence["body"]["template_path"] = str(alias)
        self.assertRejected(self.evidence, "body.template_path: environment-secret")


if __name__ == "__main__":
    unittest.main()
