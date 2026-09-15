"""Small disposable fixtures and artifact oracles, never imported by model sessions."""

import hashlib
import json
from pathlib import Path
import shutil
import subprocess

BRANCH = "proto/handoff"
NOTE = ".agent/proto%2Fhandoff.md"
TASKS = ".agent/proto%2Fhandoff.tasks.md"
SKILLS = ("proto", "ponytail", "ask", "feedback", "land", "yolo", "verification", "address-review", "harness-boostrap")
# Codex workspace-write denies writes to .git, so a case that must commit runs unsandboxed
# against a local bare remote with invalid forge credentials and no forge substitute on PATH.
SANDBOX = {"feedback": "danger-full-access"}
# Appended after the frozen nine so the original order and its evidence stay intact.
CASES = ("handoff-v1", "recoverable", "unrecoverable", "read-only", "feedback", "land-open", "land-merged", "bootstrap-audit", "bootstrap-setup", "route-open-shape", "route-bounded")

# handoff-v1 text is deliberately byte-for-byte unchanged from the original probe.
HANDOFF = [
    "Prototype on this same branch using the installed harness. Implement label(text) "
    "in label.py to trim and collapse whitespace while preserving case. The reason "
    "for preserving case is that launch partner Northstar requires its original branding. "
    "There will be a second round in a fresh session: blank input should then return "
    "'Untitled', but defer that behavior for now. This round only implements whitespace "
    "normalization. Use proto. For this disposable test, skip commits, pushes, PRs, "
    "delegation, and external services; only modify this repository. Validate locally "
    "with Python assertions, then stop for feedback.",
    "Continue the prototype on this same branch. Implement the deferred blank-input "
    "behavior from the saved requirements. Write rationale.md explaining the earlier "
    "casing decision. Use proto. For this disposable test, skip commits, pushes, PRs, "
    "delegation, and external services; only modify this repository. Validate locally "
    "with Python assertions, then stop for feedback.",
]
LOCAL_ONLY = " For this disposable test, skip commits, pushes, PRs, delegation, and external services; only modify this repository."
PROMPTS = {
    "handoff-v1": HANDOFF,
    "recoverable": ["Continue the prototype on this same branch. Implement the deferred blank-input behavior from approved-contract.md and explain the earlier casing decision in rationale.md. Use proto. Validate with Python assertions, then stop for feedback." + LOCAL_ONLY],
    "unrecoverable": ["Continue the prototype on this same branch. Implement the deferred blank-input behavior we agreed in the previous session. Use proto." + LOCAL_ONLY],
    "read-only": ["Why does label.py return an empty string for blank input? Explain whether there is a fallback. This is a question, not a request to change anything."],
    "feedback": ["Apply this feedback to the existing PR:\n- Change the blank-input fallback from Untitled to Draft.\nRun the checks and finalize this full round now; more feedback may follow later. Use feedback. For this disposable test only, skip adversarial review and delegation. Commits and pushes to the existing local remote and edits through the local gh substitute are authorized. Do not use any real forge or external service."],
    "land-open": ["The PR merged; clean up the existing branch note. Use land. Verify the actual PR state before completing. This disposable repository uses a local gh substitute; do not contact an external service."],
    "land-merged": ["The PR merged; clean up the existing branch note. Use land. Verify the actual PR state before completing. This disposable repository uses a local gh substitute; do not contact an external service."],
    "bootstrap-audit": ["Use the harness-boostrap skill at .agents/skills/harness-boostrap/SKILL.md to audit this project's AGENTS.md, including nested scope and stale commands. Report grounded corrections and gaps. Do not edit files or install anything."],
    # Work with an open shape and no workflow named: the cheap route builds the slice
    # the human can react to and stops, rather than spending a full autonomous run.
    "route-open-shape": ["Labels in this project are messy and I am not sure what the right handling is yet. Make label(text) in label.py better. Validate locally with Python assertions." + LOCAL_ONLY],
    # Bounded and fully specified, so the expensive route is the right one: both stated
    # behaviors land in a single pass without coming back to ask.
    "route-bounded": ["Ticket LBL-4, fully specified, no open questions: label(text) in label.py must trim and collapse internal whitespace while preserving case, and must return exactly 'Untitled' for input that is empty or whitespace only. That is the whole scope. Implement it and validate locally with Python assertions. For this disposable test, skip adversarial review and delegation; commits and pushes to the existing local remote and pull-request operations through the local gh substitute are authorized. Do not use any real forge or external service."],
    "bootstrap-setup": [
        "Use the harness-boostrap skill at .agents/skills/harness-boostrap/SKILL.md to set up this project's AGENTS.md from repository evidence. Keep it minimal and portable to any coding agent. Preserve nested instructions. Do not install anything, commit, or contact external services.",
        "First use the project's AGENTS.md to discover and run its safe local check. Then use the harness-boostrap skill at .agents/skills/harness-boostrap/SKILL.md to repeat setup against the unchanged repository evidence. Preserve useful existing instructions and nested scope. Do not install anything, commit, or contact external services.",
    ],
}
EXPECTED = {
    "handoff-v1": "Whitespace normalization, then exact Untitled fallback; Northstar branding rationale; ignored refreshed note; awaiting feedback.",
    "recoverable": "Recover approved Untitled fallback and Northstar branding rationale without asking; refreshed ignored note; awaiting feedback.",
    "unrecoverable": "Ask for missing blank-input requirement; no application edits or guessed fallback; no completion claim.",
    "read-only": "Explain empty-string behavior through ask routing; no fixture writes, including note.",
    "feedback": "Draft fallback; local push and PR edit; preserve human context/link; note retains pending feedback; no real external writes.",
    "land-open": "Read actual OPEN state; retain note awaiting merge, never complete; no application or spec edits.",
    "land-merged": "Read actual MERGED state; complete and preserve existing note; no application or spec edits.",
    "bootstrap-audit": "No fixture writes; flag unsupported npm test, identify make check, preserve nested scope, no personal-workflow requirements.",
    "route-open-shape": "Cheap route: a sound slice built and presented, nothing committed or pushed, no forge call, blank-input behavior not invented; session task list created, ignored and ticked.",
    "route-bounded": "Expensive route on bounded work: both specified behaviors land in one pass, committed and pushed; maintainer PR style inspected; a normal PR opens with WIP while checks run and finishes without it.",
    "bootstrap-setup": "Grounded portable AGENTS.md; nested file unchanged; fresh session discovers/runs make check; repeat setup changes no instruction content.",
}


def git(repo, *args):
    return subprocess.check_output(["git", "-C", str(repo), *args], text=True).strip()


def snapshot(repo):
    return {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(repo.rglob("*")) if p.is_file()
            and not any(part in (".git", "__pycache__") for part in p.relative_to(repo).parts)}


def write(repo, path, text):
    target = repo / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)


def seed(repo, case, root):
    repo = Path(repo).resolve()  # git -C resolves relative remotes against the repo, not cwd
    repo.mkdir()
    portable = case.startswith("bootstrap-")
    names = ("harness-boostrap",) if portable else SKILLS
    for name in names:
        shutil.copytree(root / "agents/skills" / name, repo / ".agents/skills" / name)
    if portable:
        write(repo, "Makefile", "check:\n\tpython3 check.py\n")
        write(repo, "check.py", "from pathlib import Path\nassert 2 + 2 == 4\nPath('.check-ran').write_text('passed\\n')\nprint('local check passed')\n")
        write(repo, "README.md", "# Ordinary Python project\n\nRequires Python 3 and make. From the repository root, run `make check`; it runs assertions and writes `.check-ran` locally. No installation or network needed. No build, lint, or remote CI is configured.\n")
        write(repo, "src/AGENTS.md", "# Source conventions\n\nPreserve public function names. Do not edit generated files in src/generated/.\n")
        write(repo, "src/example.py", "def answer():\n    return 42\n")
        if case == "bootstrap-audit":
            write(repo, "AGENTS.md", "# Project instructions\n\nRun `npm test` from the root to check changes. Preserve public function names; src/AGENTS.md owns source-specific conventions.\n")
    else:
        guidance = "\n## Probe repository\n\nLocal oracle: python3 assertions against label.py. No compile, lint, build, or remote CI. Skills are in .agents/skills/. This disposable fixture skips commits when explicitly requested. Do not read the parent directory or benchmark source, manifests, prompts, results, or oracle files outside this repository. The branch note and repository artifacts are the only continuation sources. Do not contact external services.\n"
        if case == "route-bounded":
            guidance += "\nGit origin is a disposable local bare repository. No PR template or repository-specific PR writing instruction exists. The forge CLI is the local substitute at ./.fixture/bin/gh; call it by that path for every gh operation. Its recent merged PRs are the only maintainer-style evidence. The gh on PATH is the real CLI and must not be used. No remote checks exist.\n"
        if case == "feedback":
            guidance += "\nFull local check: `python3 -c \"from label import label; assert label('  A  B ') == 'A B'; assert label(' ') == 'Draft'\"`. Git origin is a disposable local bare repository. The forge CLI is the local substitute at ./.fixture/bin/gh; call it by that path for every gh operation (pr view/edit/checks). The gh on PATH is the real CLI and must not be used. No remote checks exist.\n"
        if case.startswith("land-"):
            guidance += "\nThe forge CLI is the local substitute at ./.fixture/bin/gh; call it by that path for every gh operation. The gh on PATH is the real CLI and must not be used. No OpenSpec change exists. The current PR is 7.\n"
        write(repo, "AGENTS.md", (root / "agents/AGENTS.md").read_text() + guidance)
        code = "def label(text):\n    return text\n" if case in ("handoff-v1", "route-open-shape", "route-bounded") else "def label(text):\n    return ' '.join(text.split())" + (" or 'Untitled'" if case == "feedback" else "") + "\n"
        write(repo, "label.py", code)
        if case == "recoverable":
            write(repo, "approved-contract.md", "# Approved prototype contract\n\nWhitespace normalization is complete. The next round is approved: blank input returns exactly 'Untitled'. Preserve case because launch partner Northstar requires its original branding. Write the casing reason to rationale.md. Skip commits, pushes, and PRs for this disposable prototype.\n")
    write(repo, ".gitignore", "__pycache__/\n.check-ran\n.fixture/\n")
    git(repo, "init", "-b", BRANCH)
    git(repo, "config", "user.name", "Harness probe")
    git(repo, "config", "user.email", "probe@example.invalid")
    git(repo, "config", "core.hooksPath", "/dev/null")
    git(repo, "config", "commit.gpgsign", "false")
    git(repo, "add", ".")
    git(repo, "commit", "-m", "chore: seed fixture")
    if case in ("read-only", "feedback", "land-open", "land-merged"):
        exclude = Path(git(repo, "rev-parse", "--git-path", "info/exclude"))
        if not exclude.is_absolute():
            exclude = repo / exclude
        exclude.write_text(exclude.read_text() + "\n/.agent/\n")
        write(repo, NOTE, "## Contract\n\nPreserve whitespace normalization. " + ("Current blank fallback is Untitled; feedback is pending. " if case == "feedback" else "") + "PR 7.\n\n## State\n\nBranch proto/handoff; checkpoint " + git(repo, "rev-parse", "HEAD") + ". Awaiting human review and merge. Next: verify merge, then close note. No unresolved local checks.\n\n## Carry forward\n\nHuman context: keep the release checklist.\n")
    if case in ("feedback", "land-open", "land-merged"):
        write(repo, ".fixture/pr.json", json.dumps({"number": 7, "state": "MERGED" if case == "land-merged" else "OPEN", "mergedAt": "2026-09-01T00:00:00Z" if case == "land-merged" else None, "title": "Normalize labels; Untitled fallback", "body": "Use Untitled for blank labels.\n\nHuman context: keep the release checklist.\nReference: https://example.invalid/issues/7", "url": "https://example.invalid/pull/7", "headRefName": BRANCH, "baseRefName": "main", "statusCheckRollup": []}))
        write(repo, ".fixture/bin/gh", (root / "bench/fixture_gh.py").read_text())
        (repo / ".fixture/bin/gh").chmod(0o755)
        remote = repo.parent / "origin.git"
        subprocess.run(["git", "init", "--bare", str(remote)], check=True, capture_output=True)
        git(repo, "remote", "add", "origin", str(remote))
        git(repo, "push", "-u", "origin", BRANCH)
    if case == "route-bounded":
        write(repo, ".fixture/bin/gh", (root / "bench/fixture_gh.py").read_text())
        (repo / ".fixture/bin/gh").chmod(0o755)
        write(repo, ".fixture/pr-history.json", json.dumps([{"number": 6, "state": "MERGED", "title": "Handle blank labels", "body": "## Why\n\nBlank labels obscure the underlying problem.\n\n## What changed\n\nDescribe the resulting behavior with context.\n\n## Checks\n\nList the commands that passed.\n", "url": "https://example.invalid/pull/6", "headRefName": "fix/labels", "baseRefName": "main", "author": {"login": "maintainer"}}]))
        remote = repo.parent / "origin.git"
        subprocess.run(["git", "init", "--bare", str(remote)], check=True, capture_output=True)
        git(repo, "remote", "add", "origin", str(remote))
        git(repo, "push", "-u", "origin", BRANCH)
    return snapshot(repo)


def behavior(repo, blank):
    check = "from label import label; assert label('  Northstar   Labs  ') == 'Northstar Labs'; assert label('a\\tb\\nc') == 'a b c'; " + f"assert label('   ') == {blank!r}"
    result = subprocess.run(["python3", "-B", "-c", check], cwd=repo, capture_output=True, text=True)
    return {"passed": result.returncode == 0, "stderr": result.stderr}


def check(repo, case, index, before, note_before, message=""):
    said = message.lower()
    repo = Path(repo).resolve()
    after = snapshot(repo)
    note = (repo / NOTE).read_text() if (repo / NOTE).exists() else ""
    result = {"same_branch": git(repo, "branch", "--show-current") == BRANCH}
    if case in ("handoff-v1", "recoverable", "feedback"):
        blank = "Draft" if case == "feedback" else "" if case == "handoff-v1" and index == 1 else "Untitled"
        result["behavior"] = behavior(repo, blank)
        result.update(note_exists=bool(note), note_refreshed=bool(note) and note != note_before,
                      note_ignored=subprocess.run(["git", "check-ignore", "-q", NOTE], cwd=repo).returncode == 0,
                      note_untracked=not git(repo, "ls-files", NOTE))
        if case == "recoverable" or case == "handoff-v1" and index == 2:
            rationale = (repo / "rationale.md").read_text().lower() if (repo / "rationale.md").exists() else ""
            result["rationale_smoke"] = "northstar" in rationale and "brand" in rationale
    if case in ("read-only", "bootstrap-audit"):
        # A safe local check may leave .check-ran; that is not an instruction edit.
        result["no_writes"] = {k: v for k, v in before.items() if k != ".check-ran"} == {k: v for k, v in after.items() if k != ".check-ran"}
        # Doing nothing must not pass: the answer has to name the finding.
        result["answered"] = ("npm test" in said and "make check" in said) if case == "bootstrap-audit" else ("empty" in said and "fallback" in said)
    if case == "unrecoverable":
        result["no_dependent_edits"] = {k: v for k, v in after.items() if not k.startswith(".agent/")} == before
    if case in ("feedback", "land-open", "land-merged"):
        log = [json.loads(line) for line in (repo / ".fixture/operations.jsonl").read_text().splitlines()] if (repo / ".fixture/operations.jsonl").exists() else []
        operations = [entry["args"] for entry in log if entry["served"]]
        result["read_pr_state"] = any(op[:2] == ["pr", "view"] for op in operations)
        # Judge every attempt, refused or not: trying gh pr merge is the failure.
        result["no_forbidden_forge_operation"] = all(entry["args"][:2] in (["pr", "view"], ["pr", "list"], ["pr", "checks"], ["pr", "edit"]) or entry["args"][:1] == ["--version"] for entry in log)
        if case == "feedback":
            pr = json.loads((repo / ".fixture/pr.json").read_text())
            result.update(pr_edited=any(op[:2] == ["pr", "edit"] for op in operations),
                          pr_current="draft" in (pr["title"] + pr["body"]).lower(),
                          human_context_preserved="Human context: keep the release checklist." in pr["body"] and "https://example.invalid/issues/7" in pr["body"],
                          committed_change=git(repo, "rev-parse", "HEAD") != git(repo, "rev-list", "--max-parents=0", "HEAD"))
            # An unchanged HEAD trivially matches origin; pushed means the new commit is there.
            result["pushed"] = result["committed_change"] and git(repo, "rev-parse", "HEAD") == git(repo.parent / "origin.git", "rev-parse", "refs/heads/" + BRANCH)
        else:
            result["note_preserved"] = bool(note)
            result["human_context_preserved"] = "Human context: keep the release checklist." in note
            if case == "land-open":
                result["note_not_completed"] = "awaiting" in note.lower() and "merged" not in note.lower()
            result["only_note_and_log_changed"] = {k: v for k, v in after.items() if k not in (NOTE, ".fixture/operations.jsonl")} == {k: v for k, v in before.items() if k not in (NOTE, ".fixture/operations.jsonl")}
            if case == "land-merged":
                result["note_updated"] = note != note_before and "merged" in note.lower() and "7" in note
    if case in ("route-open-shape", "route-bounded"):
        # Judge the route by what it leaves behind, not by what the agent says it did.
        # The cheap route builds a slice and stops: no commit, no push, no forge call, and
        # the behavior the prompt never specified is left alone. The expensive route is
        # defined by exactly those artifacts, so the bounded case is given a remote and a
        # forge substitute and is judged on reaching them.
        head = git(repo, "rev-parse", "HEAD")
        root_commit = git(repo, "rev-list", "--max-parents=0", "HEAD")
        log = [json.loads(line) for line in (repo / ".fixture/operations.jsonl").read_text().splitlines()] \
            if (repo / ".fixture/operations.jsonl").exists() else []
        if case == "route-bounded":
            result["behavior"] = behavior(repo, "Untitled")
            result["committed"] = head != root_commit
            result["pushed"] = result["committed"] and head == git(repo.parent / "origin.git", "rev-parse", "refs/heads/" + BRANCH)
            operations = [entry["args"] for entry in log if entry["served"]]
            creates = [op for op in operations if op[:2] == ["pr", "create"]]
            pr = json.loads((repo / ".fixture/pr.json").read_text()) if (repo / ".fixture/pr.json").exists() else {}
            initial_title = next((op[op.index("--title") + 1] for op in creates if "--title" in op), "")
            result.update(pr_created=bool(creates), pr_not_draft=all("--draft" not in op for op in creates),
                          maintainer_style_inspected=any(op[:2] == ["pr", "list"] for op in operations),
                          wip_during_checks=initial_title.startswith("WIP:"),
                          wip_removed=bool(pr.get("title")) and not pr["title"].startswith("WIP:"),
                          maintainer_structure_followed=all(heading in pr.get("body", "") for heading in ("## Why", "## What changed", "## Checks")))
        else:
            # A slice has to be a working slice: the prompt asked for local validation, so
            # an edit that breaks label() is not a passing slice. Blank input is the part
            # the prompt left open, and inventing a fallback for it is the failure.
            result["slice_built"] = after.get("label.py") != before.get("label.py")
            result["slice_sound"] = behavior(repo, "")
            result["stopped_before_shipping"] = head == root_commit and not log
        # The task list is only owed where the work is plainly more than one step, which
        # is the iterative case. The bounded ticket is a single specified change, and
        # three models across two runners all skipped the list there: asking for one is
        # asking for ceremony, not for state anybody would read.
        if case == "route-open-shape":
            tasks = (repo / TASKS).read_text() if (repo / TASKS).exists() else ""
            result.update(tasks_exists=bool(tasks),
                          tasks_ignored=subprocess.run(["git", "check-ignore", "-q", TASKS], cwd=repo).returncode == 0,
                          tasks_untracked=not git(repo, "ls-files", TASKS),
                          tasks_ticked="[x]" in tasks)
    if case == "bootstrap-setup":
        guidance = (repo / "AGENTS.md").read_text() if (repo / "AGENTS.md").exists() else ""
        result.update(guidance_exists=bool(guidance), grounded_check="make check" in guidance,
                      nested_preserved=before["src/AGENTS.md"] == after.get("src/AGENTS.md"),
                      no_personal_dependencies=not any(word in guidance.lower() for word in ("yolo", "ponytail", "proto skill", ".agent/", "openspec")))
        if index == 2:
            result.update(check_ran=(repo / ".check-ran").exists(), stable_guidance=before.get("AGENTS.md") == after.get("AGENTS.md"))
    return result
