"""Focused contract checks for workspace and PR ticket linkage."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from check_task_linkage import validate_launch, validate_ticket_links


SCRIPT = Path(__file__).with_name("check_task_linkage.py")


def ticket(identifier="DEMO-7", **extra):
    return {"id": identifier, "tracker": "linear", **extra}


def launch(**extra):
    return {"git_repository": True, "tickets": [ticket()], "launch": {
        "workspaceStrategy": {"type": "worktree", "branch": "fix/deMo-7-linkage",
                              "baseRef": "main", "startFromOrigin": True}}, **extra}


class LaunchTests(unittest.TestCase):
    def test_fresh_worktree(self):
        self.assertEqual(validate_launch(launch()), [])
        data = launch()
        data["launch"]["workspaceStrategy"]["branch"] = "fix/DEMO-70"
        self.assertTrue(validate_launch(data))

    def test_root_default_requires_explicit_reuse(self):
        data = launch()
        data["launch"]["workspaceStrategy"] = {"type": "root"}
        self.assertTrue(validate_launch(data))
        data["reuse_reason"] = "User requested continuing in the current checkout"
        self.assertEqual(validate_launch(data), [])

    def test_existing_worktree_reuses_without_rename(self):
        data = launch(reuse_reason="User selected this existing workspace")
        data["launch"]["workspaceStrategy"] = {"type": "existing_worktree"}
        self.assertTrue(validate_launch(data))
        data["launch"]["workspaceStrategy"]["worktreePath"] = "/tmp/already-present"
        self.assertEqual(validate_launch(data), [])
        data["launch"]["workspaceStrategy"]["branch"] = "DEMO-7"
        self.assertTrue(validate_launch(data))

    def test_branch_exception(self):
        data = launch(branch_exception={"basis": "explicit-user-choice", "reason": "User chose exact branch"})
        data["launch"]["workspaceStrategy"]["branch"] = "user-chosen"
        self.assertEqual(validate_launch(data), [])
        data["branch_exception"]["basis"] = "existing-published-branch"
        self.assertTrue(validate_launch(data))

    def test_no_tickets_and_non_git(self):
        data = launch(tickets=[])
        data["launch"]["workspaceStrategy"]["branch"] = "feature/plain"
        self.assertEqual(validate_launch(data), [])
        data["git_repository"] = False
        self.assertTrue(validate_launch(data))
        data["launch"]["workspaceStrategy"] = {"type": "root"}
        self.assertEqual(validate_launch(data), [])
        data["launch"] = {"title": "Non-git task"}
        self.assertEqual(validate_launch(data), [])
        data["launch"] = {"title": "Scratch task", "scratch": True}
        self.assertEqual(validate_launch(data), [])
        data["launch"]["workspaceStrategy"] = {"type": "scratch"}
        self.assertTrue(validate_launch(data))
        data["launch"] = {"scratch": "true"}
        self.assertTrue(validate_launch(data))

    def test_required_launch_metadata(self):
        for key in ("git_repository", "tickets", "launch"):
            data = launch()
            del data[key]
            self.assertTrue(validate_launch(data), key)
        for value in (None, [], "launch", 1):
            self.assertTrue(validate_launch(value))
        for key in ("type", "branch", "baseRef", "startFromOrigin"):
            data = launch()
            del data["launch"]["workspaceStrategy"][key]
            self.assertTrue(validate_launch(data), key)
        for value in (None, "default", {}, {"type": "default"}, []):
            data = launch()
            data["launch"]["workspaceStrategy"] = value
            self.assertTrue(validate_launch(data))
        for key, value in (("git_repository", 1), ("tickets", {})):
            self.assertTrue(validate_launch(launch(**{key: value})))
        data = launch()
        data["launch"]["workspaceStrategy"]["startFromOrigin"] = "true"
        self.assertTrue(validate_launch(data))


class PrTests(unittest.TestCase):
    def test_all_tickets_need_their_own_reference(self):
        tickets = [ticket(relation="resolves"), ticket("bug123", tracker="git-bug", relation="refs", reason="Related follow-up")]
        self.assertEqual(validate_ticket_links("fix/DEMO-7", tickets, "Resolves DEMO-7\nRefs bug123"), [])
        self.assertTrue(validate_ticket_links("fix/DEMO-7", tickets, "Resolves DEMO-7"))
        self.assertTrue(validate_ticket_links("fix/DEMO-7", tickets, "Resolves DEMO-7\nResolves bug123"))

    def test_refs_requires_reason(self):
        tickets = [ticket(relation="refs")]
        self.assertTrue(validate_ticket_links("fix/DEMO-7", tickets, "Refs DEMO-7"))
        tickets[0]["reason"] = "Partial implementation"
        self.assertEqual(validate_ticket_links("fix/DEMO-7", tickets, "Refs DEMO-7"), [])

    def test_mentions_fences_and_prefixes_do_not_resolve(self):
        tickets = [ticket(relation="resolves")]
        bodies = ["Working on DEMO-7", "Resolves DEMO-70", "Resolves `DEMO-7`",
                  "```text\nResolves DEMO-7\n```", "~~~\nResolves DEMO-7\n~~~",
                  "````\n```\nResolves DEMO-7\n````", "    Resolves DEMO-7"]
        for body in bodies:
            self.assertTrue(validate_ticket_links("fix/DEMO-7", tickets, body), body)
        self.assertEqual(validate_ticket_links("fix/DEMO-7", tickets, "```\nexample\n```\nResolves demo-7"), [])

    def test_branch_exceptions_and_no_tickets(self):
        tickets = [ticket(relation="resolves")]
        for basis in ("explicit-user-choice", "existing-published-branch"):
            self.assertEqual(validate_ticket_links("chosen", tickets, "Resolves DEMO-7", {"basis": basis, "reason": "Recorded choice"}), [])
        for exception in (False, [], {}, {"basis": "other", "reason": "choice"}, {"basis": "explicit-user-choice", "reason": " "}):
            self.assertTrue(validate_ticket_links("fix/DEMO-7", tickets, "Resolves DEMO-7", exception))
        self.assertEqual(validate_ticket_links("plain", [], ""), [])
        self.assertTrue(validate_ticket_links(" ", [], ""))

    def test_invalid_ticket_metadata(self):
        for tickets in (None, {}, "DEMO-7", [None], [{}], [ticket(relation="unknown")],
                        [ticket(tracker="github", relation="resolves")], [ticket(" ", relation="resolves")],
                        [ticket(relation="resolves"), ticket("demo-7", relation="resolves")]):
            self.assertTrue(validate_ticket_links("fix/DEMO-7", tickets, "Resolves DEMO-7"))
        self.assertTrue(validate_ticket_links("fix/DEMO-7", [ticket(relation="resolves")], None))


class CliTests(unittest.TestCase):
    def run_cli(self, args, data):
        return subprocess.run([sys.executable, str(SCRIPT), *args], input=data,
                              text=True, capture_output=True, check=False)

    def test_launch_exit_codes_and_no_input_echo(self):
        self.assertEqual(self.run_cli(["launch"], json.dumps(launch())).returncode, 0)
        self.assertEqual(self.run_cli(["launch"], "{}").returncode, 1)
        for raw in ("[1]", "null", "\"arbitrary\"", "{invalid-sensitive-marker"):
            result = self.run_cli(["launch"], raw)
            self.assertEqual(result.returncode, 2)
            self.assertNotIn("sensitive-marker", result.stderr)

    def test_pr_body_and_forbidden_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            body = root / "body.md"
            body.write_text("Resolves DEMO-7", encoding="utf-8")
            args = ["pr", "--branch", "fix/DEMO-7", "--body-file", str(body)]
            payload = json.dumps({"tickets": [ticket(relation="resolves")]})
            self.assertEqual(self.run_cli(args, payload).returncode, 0)
            self.assertEqual(self.run_cli(args, "{}").returncode, 1)
            forbidden = root / ".env-test-never-created"
            for path in (forbidden, root / ".env-directory" / "body.md"):
                args[-1] = str(path)
                self.assertEqual(self.run_cli(args, payload).returncode, 2)
            alias = root / "alias.md"
            alias.symlink_to(forbidden)
            args[-1] = str(alias)
            self.assertEqual(self.run_cli(args, payload).returncode, 2)


if __name__ == "__main__":
    unittest.main()
