#!/usr/bin/env python3
"""Local forge substitute; unsupported operations fail and are logged as refused."""
import json
from pathlib import Path
import subprocess
import sys

root = Path(subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()) / ".fixture"
args = sys.argv[1:]
served = False


def log():
    with (root / "operations.jsonl").open("a") as stream:
        stream.write(json.dumps({"args": args, "served": served}) + "\n")


try:
    pr_path = root / "pr.json"
    pr = json.loads(pr_path.read_text()) if pr_path.exists() else None
    history_path = root / "pr-history.json"
    history = json.loads(history_path.read_text()) if history_path.exists() else []
    if args[:2] in (["pr", "view"], ["pr", "list"]):
        if args[1] == "view" and pr is None:
            sys.exit("No pull request found")
        value = ([pr] if pr else []) + history if args[1] == "list" else pr
        if "--jq" in args:
            query = args[args.index("--jq") + 1]
            if pr is None or not (query.startswith(".") and query[1:] in pr):
                sys.exit("Unsupported fixture jq expression")
            field = pr[query[1:]]
            print(field if isinstance(field, str) else json.dumps(field))
        elif "--json" in args or args[1] == "list":
            print(json.dumps(value))
        else:
            print(f"{pr['title']} #{pr['number']}\n{pr['state']} · {pr['headRefName']} -> {pr['baseRefName']}\n{pr['url']}")
        served = True
    elif args[:2] == ["pr", "create"]:
        def option(name, default=""):
            return args[args.index(name) + 1] if name in args else default

        body_file = option("--body-file")
        pr = {"number": 8, "state": "OPEN", "mergedAt": None, "title": option("--title"),
              "body": Path(body_file).read_text() if body_file else option("--body"),
              "url": "https://example.invalid/pull/8", "headRefName": "proto/handoff",
              "baseRefName": option("--base", "main"), "statusCheckRollup": [],
              "isDraft": "--draft" in args}
        pr_path.write_text(json.dumps(pr))
        print(pr["url"])
        served = True
    elif args[:2] == ["pr", "checks"]:
        print("[]" if "--json" in args else "No required checks")
        served = True
    elif args[:2] == ["pr", "edit"]:
        if pr is None:
            sys.exit("No pull request found")
        for option, field in (("--title", "title"), ("--body", "body"), ("--body-file", "body")):
            if option in args:
                value = args[args.index(option) + 1]
                pr[field] = (sys.stdin.read() if value == "-" else Path(value).read_text()) if option == "--body-file" else value
                served = True
        if not served:
            sys.exit("Fixture pr edit supports only --title, --body, --body-file")
        pr_path.write_text(json.dumps(pr))
        print(pr["url"])
    else:
        sys.exit("Unsupported fixture operation; no external service was called")
finally:
    log()
