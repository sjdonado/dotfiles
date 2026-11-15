#!/usr/bin/env python3
"""Validate recorded ticket linkage and actual T3 launch arguments; no mutations."""

import argparse
import json
from pathlib import Path
import re
import sys


def _nonblank(value):
    return isinstance(value, str) and bool(value.strip())


def _tickets(tickets, require_relation=False):
    errors, valid, seen = [], [], set()
    if not isinstance(tickets, list):
        return ["tickets must be a list (use [] for no tickets)"], valid
    for index, ticket in enumerate(tickets):
        label = f"tickets[{index}]"
        if not isinstance(ticket, dict):
            errors.append(f"{label} must be an object")
            continue
        identifier = ticket.get("id")
        if not _nonblank(identifier) or "\n" in identifier or "\r" in identifier:
            errors.append(f"{label}.id must be nonblank and single-line")
        else:
            identifier = identifier.strip()
            if identifier.casefold() in seen:
                errors.append(f"{label}.id must be unique")
            seen.add(identifier.casefold())
            valid.append((index, identifier, ticket))
        if ticket.get("tracker") not in ("linear", "git-bug"):
            errors.append(f"{label}.tracker must be linear or git-bug")
        if require_relation:
            if ticket.get("relation") not in ("resolves", "refs"):
                errors.append(f"{label}.relation must be resolves or refs")
            elif ticket["relation"] == "refs" and not _nonblank(ticket.get("reason")):
                errors.append(f"{label}.reason is required for refs")
    return errors, valid


def _branch_errors(branch, tickets, exception, fresh=False):
    errors = []
    allowed = ("explicit-user-choice",) if fresh else (
        "explicit-user-choice", "existing-published-branch")
    if exception is not None and (
        not isinstance(exception, dict) or exception.get("basis") not in allowed
        or not _nonblank(exception.get("reason"))
    ):
        errors.append("branch_exception requires an allowed basis and nonblank reason")
    if not _nonblank(branch):
        errors.append("branch must be nonblank")
    elif tickets and tickets[0][0] == 0 and exception is None:
        identifier = tickets[0][1]
        if not re.search(r"(?<![A-Za-z0-9])" + re.escape(identifier)
                         + r"(?![A-Za-z0-9])", branch, re.IGNORECASE):
            errors.append("branch must contain the primary ticket ID as a delimited token")
    return errors


def _plain_lines(body):
    fence = None
    for line in body.splitlines():
        marker = re.match(r"^ {0,3}(`{3,}|~{3,})(.*)$", line)
        if fence:
            if marker and marker[1][0] == fence[0] and len(marker[1]) >= len(fence) and not marker[2].strip():
                fence = None
        elif marker:
            fence = marker[1]
        else:
            yield line


def validate_ticket_links(branch, tickets, body_text, branch_exception=None):
    """Return errors for PR linkage; the first ticket is primary."""
    errors, valid = _tickets(tickets, require_relation=True)
    errors.extend(_branch_errors(branch, valid, branch_exception))
    if not isinstance(body_text, str):
        return errors + ["PR body must be text"]
    lines = list(_plain_lines(body_text))
    for index, identifier, ticket in valid:
        if ticket.get("relation") not in ("resolves", "refs"):
            continue
        verb = ticket["relation"].capitalize()
        pattern = r"^[ \t]{0,3}" + verb + r"[ \t]+" + re.escape(identifier) + r"\.?[ \t]*$"
        if not any(re.fullmatch(pattern, line, re.IGNORECASE) for line in lines):
            errors.append(f"tickets[{index}] requires a plain {verb} reference line outside fences")
    return errors


def validate_launch(data):
    """Return errors for a launch record containing actual T3 arguments."""
    if not isinstance(data, dict):
        return ["launch record must be an object"]
    errors, tickets = _tickets(data.get("tickets"))
    if type(data.get("git_repository")) is not bool:
        errors.append("git_repository must be a boolean")
    launch = data.get("launch")
    if not isinstance(launch, dict):
        return errors + ["launch must contain the actual tool argument object"]
    if "scratch" in launch and type(launch["scratch"]) is not bool:
        errors.append("launch.scratch must be a boolean when supplied")
    strategy = launch.get("workspaceStrategy")
    if data.get("git_repository") is False:
        if launch.get("scratch") is True:
            if strategy is not None or launch.get("projectId") is not None:
                errors.append("scratch uses the top-level scratch flag without projectId or workspaceStrategy")
        elif strategy is not None and (not isinstance(strategy, dict) or strategy.get("type") != "root"):
            errors.append("non-git launches cannot request a git worktree")
        return errors
    if launch.get("scratch"):
        errors.append("git launches cannot substitute a scratch workspace")
    if not isinstance(strategy, dict):
        return errors + ["launch.workspaceStrategy must be an explicit object"]
    kind = strategy.get("type")
    if kind == "worktree":
        errors.extend(_branch_errors(strategy.get("branch"), tickets,
                                     data.get("branch_exception"), fresh=True))
        if not _nonblank(strategy.get("baseRef")):
            errors.append("worktree baseRef must be nonblank")
        if type(strategy.get("startFromOrigin")) is not bool:
            errors.append("worktree startFromOrigin must be a boolean")
    elif kind in ("root", "existing_worktree"):
        if not _nonblank(data.get("reuse_reason")):
            errors.append("reusing a git workspace requires reuse_reason recording an explicit user instruction")
        if kind == "existing_worktree" and not _nonblank(strategy.get("worktreePath")):
            errors.append("existing_worktree requires worktreePath")
        if "branch" in strategy:
            errors.append("workspace reuse must not request a branch rename")
    else:
        errors.append("git launches require worktree or explicitly authorized workspace reuse")
    return errors


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("launch")
    pr = sub.add_parser("pr")
    pr.add_argument("--branch", required=True)
    pr.add_argument("--body-file", required=True)
    args = parser.parse_args(argv)
    try:
        data = json.load(sys.stdin)
        if not isinstance(data, dict):
            raise ValueError
        if args.command == "launch":
            errors = validate_launch(data)
        else:
            path = Path(args.body_file).expanduser()
            if any(part.lower().startswith(".env") for candidate in (path, path.resolve()) for part in candidate.parts):
                raise ValueError
            if not path.is_file():
                raise ValueError
            errors = validate_ticket_links(args.branch, data.get("tickets"),
                                          path.read_text(encoding="utf-8"), data.get("branch_exception"))
    except (ValueError, OSError, RuntimeError, RecursionError):
        print("Invalid JSON input or unreadable/forbidden PR body file", file=sys.stderr)
        return 2
    for error in errors:
        print(error, file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
