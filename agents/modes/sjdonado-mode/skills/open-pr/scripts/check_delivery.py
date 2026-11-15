#!/usr/bin/env python3
"""Check declared delivery evidence structure and local artifact metadata.

This reads the supplied PR body but never executes commands or reads evidence
artifacts, and cannot prove command
execution, semantic coverage, or truthfulness of the declared evidence.
Relative artifact paths are interpreted from the caller's working directory.
"""

import argparse
import json
from pathlib import Path
import re
import stat
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[5] / "scripts"))
from check_task_linkage import validate_ticket_links


def demo_section(body, heading):
    """Find a real Markdown section, ignoring headings inside fenced code."""
    collecting, fence = False, None
    content = []
    for line in body.splitlines():
        marker = re.match(r"^ {0,3}(`{3,}|~{3,})", line)
        if marker:
            token = marker.group(1)
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence):
                fence = None
        elif fence is None:
            title = re.match(r"^ {0,3}#{1,6}[ \t]+(.+?)[ \t]*#*[ \t]*$", line)
            if title:
                if collecting:
                    break
                collecting = title.group(1).casefold() == heading.casefold()
                continue
        if collecting:
            content.append(line)
    return "\n".join(content) if collecting else None


def validate(data, expected_revision, body_text, branch):
    """Return concise field errors; inspect artifact metadata only."""
    errors = []

    def nonblank(value):
        return isinstance(value, str) and bool(value.strip())

    def text_field(obj, key, location):
        if not nonblank(obj.get(key)):
            errors.append(f"{location}.{key}: expected nonblank string")

    def revision(obj, location):
        if not nonblank(obj.get("source_revision")) or obj["source_revision"] != expected_revision:
            errors.append(f"{location}.source_revision: must match expected revision")

    def artifact(obj, location):
        value = obj.get("artifact")
        if not nonblank(value):
            errors.append(f"{location}.artifact: expected nonblank local file path")
            return
        path = Path(value)
        if any(part.startswith(".env") for part in path.parts):
            errors.append(f"{location}.artifact: environment-secret paths are forbidden")
            return
        try:
            path = path.resolve()
            if any(part.startswith(".env") for part in path.parts):
                errors.append(f"{location}.artifact: environment-secret paths are forbidden")
                return
            info = path.stat()
            if not stat.S_ISREG(info.st_mode) or info.st_size == 0:
                errors.append(f"{location}.artifact: must be an existing nonempty file")
        except (OSError, ValueError, RuntimeError):
            errors.append(f"{location}.artifact: must be an existing nonempty local file")

    if not nonblank(expected_revision):
        return ["expected_revision: expected nonblank string"]
    if not isinstance(data, dict):
        return ["evidence: expected object"]
    if not isinstance(body_text, str) or not body_text.strip():
        return ["pr_body: expected nonempty text"]
    errors.extend(validate_ticket_links(branch, data.get("tickets"), body_text, data.get("branch_exception")))
    change_type = data.get("change_type")
    if change_type not in ("functional", "nonfunctional"):
        errors.append("change_type: expected functional or nonfunctional")
    functional = change_type == "functional"
    revision(data, "evidence")

    requirements = data.get("requirements")
    if not isinstance(requirements, list):
        errors.append("requirements: expected list")
        requirements = []
    if functional and not requirements:
        errors.append("requirements: functional changes require at least one requirement")
    if change_type == "nonfunctional" and requirements:
        errors.append("requirements: nonfunctional changes require an empty list")
    required_ids = set()
    for index, requirement in enumerate(requirements):
        location = f"requirements[{index}]"
        if not isinstance(requirement, dict):
            errors.append(f"{location}: expected object")
            continue
        text_field(requirement, "id", location)
        text_field(requirement, "behavior", location)
        identifier = requirement.get("id")
        if nonblank(identifier):
            if identifier in required_ids:
                errors.append(f"{location}.id: duplicate requirement")
            required_ids.add(identifier)

    checks = data.get("checks")
    if not isinstance(checks, list):
        errors.append("checks: expected list")
        checks = []
    if change_type == "nonfunctional" and checks:
        errors.append("checks: nonfunctional changes require an empty list")
    checked_ids = set()
    for index, check in enumerate(checks):
        location = f"checks[{index}]"
        if not isinstance(check, dict):
            errors.append(f"{location}: expected object")
            continue
        text_field(check, "requirement_id", location)
        identifier = check.get("requirement_id")
        if nonblank(identifier):
            if identifier not in required_ids:
                errors.append(f"{location}.requirement_id: no matching requirement")
            if identifier in checked_ids:
                errors.append(f"{location}.requirement_id: duplicate decisive row")
            checked_ids.add(identifier)
        if check.get("status") not in ("executed", "unverified"):
            errors.append(f"{location}.status: expected executed or unverified")
        elif functional and check["status"] != "executed":
            errors.append(f"{location}.status: functional evidence must be executed")
        if check.get("kind") not in ("runtime", "static"):
            errors.append(f"{location}.kind: expected runtime or static")
        elif functional and check["kind"] != "runtime":
            errors.append(f"{location}.kind: functional evidence must be runtime")
        for field in ("entry_point", "scenario", "expected", "observed", "command"):
            text_field(check, field, location)
        revision(check, location)
        artifact(check, location)
    if required_ids - checked_ids:
        errors.append("checks: missing decisive row for one or more requirements")

    demo = data.get("demo")
    if not isinstance(demo, dict):
        errors.append("demo: expected object")
        return errors
    text_field(demo, "reason", "demo")
    revision(demo, "demo")
    status = demo.get("status")
    if status not in ("capture", "command", "not_applicable", "blocked"):
        errors.append("demo.status: expected capture, command, not_applicable or blocked")
    elif functional:
        heading = demo.get("heading", "Demo")
        if not nonblank(heading):
            errors.append("demo.heading: expected nonblank heading")
        elif not (demo_section(body_text, heading) or "").strip():
            errors.append("pr_body: missing or empty demo section")
        if status in ("not_applicable", "blocked"):
            errors.append("demo.status: functional changes require capture or command")
        else:
            artifact(demo, "demo")
            if status == "capture" and demo.get("inspected") is not True:
                errors.append("demo.inspected: capture must be inspected")
            if status == "command":
                text_field(demo, "command", "demo")
    elif change_type == "nonfunctional" and status != "not_applicable":
        errors.append("demo.status: nonfunctional changes require not_applicable")
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--body-file", required=True)
    parser.add_argument("--branch", required=True)
    args = parser.parse_args()
    body_path = Path(args.body_file)
    try:
        if any(part.startswith(".env") for part in body_path.parts):
            raise ValueError()
        body_path = body_path.resolve()
        if any(part.startswith(".env") for part in body_path.parts):
            raise ValueError()
        if not body_path.is_file():
            raise ValueError()
        body_text = body_path.read_text(encoding="utf-8")
    except (OSError, ValueError, RuntimeError, UnicodeError):
        print("pr_body: unavailable or forbidden body file", file=sys.stderr)
        return 1
    try:
        data = json.load(sys.stdin)
    except (ValueError, RecursionError):
        print("evidence: invalid JSON", file=sys.stderr)
        return 1
    errors = validate(data, args.source_revision, body_text, args.branch)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    print("Declared delivery evidence, demo section and artifact metadata are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
