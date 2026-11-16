#!/usr/bin/env python3
"""Check declared delivery evidence structure and local artifact metadata.

This reads the supplied PR body but never executes commands or reads evidence
artifacts or template contents, and cannot prove command execution, semantic
coverage, template selection, or truthfulness of the declared evidence.
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


FALLBACK_HEADINGS = ("Summary", "Reviewer notes", "Verification", "Demo")


def markdown_sections(body):
    """Parse headings outside comments/fences, retaining nested section content."""
    lines = re.sub(r"<!--[\s\S]*?(?:-->|$)", "", body).splitlines()
    headings, fence = [], None
    for index, line in enumerate(lines):
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
                level = len(line.lstrip().split(None, 1)[0])
                headings.append((index, level, title.group(1).strip()))
    sections = []
    for index, (start, level, title) in enumerate(headings):
        end = next((row[0] for row in headings[index + 1:] if row[1] <= level), len(lines))
        sections.append((title.casefold(), start, "\n".join(lines[start + 1:end])))
    return sections


def meaningful_content(text):
    """Reject empty Markdown shells and untouched placeholder-only sections."""
    lines = []
    for line in text.splitlines():
        if re.match(r"^ {0,3}(?:`{3,}|~{3,}|#{1,6}[ \t])", line):
            continue
        if re.fullmatch(r"\s*[-*_]{3,}\s*", line):
            continue
        lines.append(line)
    value = "\n".join(lines).strip(" \t\r\n*-_[]<>.!:")
    return bool(value) and not re.fullmatch(r"(?i)(?:todo|tbd|placeholder|coming soon)", value)


def demo_section(body, heading):
    matches = [content for title, _, content in markdown_sections(body) if title == heading.casefold()]
    return matches[0] if len(matches) == 1 else None


def unfenced_text(text):
    """Do not treat labels inside example code as verification statements."""
    result, fence = [], None
    for line in text.splitlines():
        marker = re.match(r"^ {0,3}(`{3,}|~{3,})", line)
        if marker:
            token = marker.group(1)
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence):
                fence = None
        elif fence is None:
            result.append(line)
    return "\n".join(result)


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

    def artifact(obj, location, key="artifact"):
        field = f"{location}.{key}"
        value = obj.get(key)
        if not nonblank(value):
            errors.append(f"{field}: expected nonblank local file path")
            return
        path = Path(value)
        if any(part.startswith(".env") for part in path.parts):
            errors.append(f"{field}: environment-secret paths are forbidden")
            return
        try:
            path = path.resolve()
            if any(part.startswith(".env") for part in path.parts):
                errors.append(f"{field}: environment-secret paths are forbidden")
                return
            info = path.stat()
            if not stat.S_ISREG(info.st_mode) or info.st_size == 0:
                errors.append(f"{field}: must be an existing nonempty file")
        except (OSError, ValueError, RuntimeError):
            errors.append(f"{field}: must be an existing nonempty local file")

    def body_structure(functional):
        body = data.get("body")
        if not isinstance(body, dict):
            errors.append("body: expected template selection object")
            return
        template = body.get("template")
        if template == "fallback":
            required = list(FALLBACK_HEADINGS)
            summary_heading, verification_heading = "Summary", "Verification"
            if isinstance(data.get("demo"), dict) and data["demo"].get("heading", "Demo") != "Demo":
                errors.append("demo.heading: fallback template requires Demo")
        elif template == "repository":
            artifact(body, "body", "template_path")
            required = body.get("required_headings")
            summary_heading, verification_heading = body.get("summary_heading"), body.get("verification_heading")
            if not isinstance(required, list) or not required or any(not nonblank(title) for title in required):
                errors.append("body.required_headings: expected nonempty list of heading titles")
                return
            normalized = [title.strip().casefold() for title in required]
            if len(set(normalized)) != len(normalized):
                errors.append("body.required_headings: heading titles must be distinct")
                return
            if (not nonblank(summary_heading) or not nonblank(verification_heading)
                    or summary_heading.strip().casefold() == verification_heading.strip().casefold()
                    or summary_heading.strip().casefold() not in normalized
                    or verification_heading.strip().casefold() not in normalized):
                errors.append("body: distinct summary_heading and verification_heading must be required headings")
                return
            demo = data.get("demo")
            demo_heading = demo.get("heading", "Demo") if isinstance(demo, dict) else "Demo"
            if functional and (not nonblank(demo_heading) or demo_heading.strip().casefold() not in normalized):
                errors.append("body.required_headings: functional demo heading must be required")
        else:
            errors.append("body.template: expected fallback or repository")
            return

        sections = markdown_sections(body_text)
        required_titles = {heading.strip().casefold() for heading in required}
        required_positions = [position for title, position, _ in sections if title in required_titles]

        def own_content(position, content):
            # A nested required section cannot fill an otherwise empty parent.
            end = min((start for start in required_positions if start > position), default=None)
            return "\n".join(content.splitlines()[:end - position - 1]) if end is not None else content

        positions = []
        for heading in required:
            matches = [(position, content) for title, position, content in sections if title == heading.strip().casefold()]
            if len(matches) != 1:
                errors.append(f"pr_body: required section {heading!r} must occur exactly once")
                continue
            position, content = matches[0]
            positions.append(position)
            if not meaningful_content(own_content(position, content)):
                errors.append(f"pr_body: required section {heading!r} is empty or a placeholder")
        if positions != sorted(positions):
            errors.append("pr_body: required sections are out of template order")
        verification = [own_content(position, content) for title, position, content in sections if title == verification_heading.strip().casefold()]
        label = re.compile(r"^[ \t]*(?:[-*+][ \t]+)?(?:\*\*)?(?:Executed|Static)(?:[ \t]*\([^\n)]*\))?(?:\*\*)?[ \t]*:(?:\*\*)?[ \t]*(\S[^\n]*)", re.I | re.M)
        if len(verification) == 1 and not any(meaningful_content(match.group(1)) for match in label.finditer(unfenced_text(verification[0]))):
            errors.append("pr_body: verification needs an Executed or Static label with an observed check result")

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
    body_structure(functional)

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
        elif not meaningful_content(demo_section(body_text, heading) or ""):
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
    print("Declared delivery evidence, PR body structure and artifact metadata are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
