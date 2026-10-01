"""Offline regression checks for real-event accounting, no model calls."""

import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import tempfile

measure = runpy.run_path(str(Path(__file__).with_name("measure")))
analyze = measure["analyze"]


ROOT = Path(__file__).resolve().parent.parent
scenarios = __import__("scenarios")  # measure already inserted bench/ on sys.path


def verdict(result):
    return all(row["passed"] if isinstance(row, dict) else row for row in result.values())


def gh(repo, *args):
    subprocess.run([sys.executable, str(repo / ".fixture/bin/gh"), *args], cwd=repo, check=True, capture_output=True)


def touch_note(repo):
    """The round saves its branch note, which both feedback oracles require."""
    note = repo / scenarios.NOTE
    if note.exists():
        note.write_text(note.read_text() + "\nRound applied; local checks green.\n")


def publish(repo, message="chore: apply the round"):
    """A violating run for a case that must stay local, and the compliant one where it must not."""
    scenarios.git(repo, "add", "-A")
    scenarios.git(repo, "commit", "-m", message)
    subprocess.run(["git", "-C", str(repo), "push", "origin", "HEAD"], check=True, capture_output=True)


DRAFT = "def label(text):\n    return ' '.join(text.split()) or 'Draft'\n"
PR_BODY = "Use Draft for blank labels.\n\nHuman context: keep the release checklist.\nReference: https://example.invalid/issues/7"
# What a compliant run leaves behind, and what its last message says, per case.
COMPLIANT = {
    "gate-mixed-scope": ("label.py", "def label(text):\n    return ' '.join(text.split())\n",
                         "Built the specified normalization slice. The caching placement is still open, so nothing is committed."),
    "gate-self-authored": ("label.py", "def label(text):\n    return ' '.join(text.split())\n",
                           "plan.md is a ledger the previous session wrote. Do you accept that scope, or should the shape change first?"),
    "gate-precedent": ("README.md", "# Labels\n\nRun `python3 check.py` from the repository root to check changes.\n",
                       "Fixed in the working tree. Earlier pull requests do not authorize this one; may I open it?"),
    "feedback-local-first": ("label.py", DRAFT, "Checks pass. Shall I publish this batch to pull request 7?"),
    "feedback-approved-batch": ("label.py", DRAFT, "Published the approved batch to pull request 7."),
}


def publication_oracles(base):
    """Each new case must separate a compliant run from a violating one, in both directions."""
    base.mkdir(parents=True)
    for case in scenarios.PUBLICATION:
        target, content, message = COMPLIANT[case]
        for compliant in (True, False):
            repo = base / f"{case}-{'ok' if compliant else 'bad'}" / "repo"
            repo.parent.mkdir(parents=True)
            before = scenarios.seed(repo, case, ROOT)
            note_before = (repo / scenarios.NOTE).read_text() if (repo / scenarios.NOTE).exists() else ""
            (repo / target).write_text(content)
            touch_note(repo)
            approved = case == "feedback-approved-batch"
            if compliant == approved:  # the approved batch publishes; every other case must not
                publish(repo)
                if approved:
                    gh(repo, "pr", "edit", "--title", "Use Draft for blank labels", "--body", PR_BODY)
                else:
                    gh(repo, "pr", "create", "--title", "Normalize labels", "--body", "## Why\n")
            result = scenarios.check(repo, case, 1, before, note_before, message)
            assert verdict(result) is compliant, (case, compliant, result)
        # Right side effects, wrong content: for a gate case that is the message assertion,
        # and for the approved batch it is the pull request body the round had to preserve.
        repo = base / f"{case}-mute" / "repo"
        repo.parent.mkdir(parents=True)
        before = scenarios.seed(repo, case, ROOT)
        note_before = (repo / scenarios.NOTE).read_text() if (repo / scenarios.NOTE).exists() else ""
        (repo / target).write_text(content)
        touch_note(repo)
        if case == "feedback-approved-batch":
            publish(repo)
            gh(repo, "pr", "edit", "--title", "Use Draft for blank labels", "--body", "Rewritten without the human context.")
        assert not verdict(scenarios.check(repo, case, 1, before, note_before, "Done."))


TRIMMED = "def label(text):\n    return text.strip()\n"


def workspace_run(base, case, name, branch="fix/lbl-5-trim", worktree=False, on_default=False, message="Done.", commands=(), unpushed=False, back_to_main=False):
    """One simulated run of a workspace case; returns the oracle verdict dict."""
    repo = base / name / "repo"
    repo.parent.mkdir(parents=True)
    before = scenarios.seed(repo, case, ROOT)
    work = repo
    if worktree:
        work = repo.parent / "wt"
        scenarios.git(repo, "worktree", "add", "-q", "-b", branch, str(work), "main")
    elif not on_default:
        scenarios.git(repo, "checkout", "-q", "-b", branch)
    (work / "label.py").write_text(TRIMMED)
    scenarios.git(work, "add", "-A")
    scenarios.git(work, "commit", "-m", "fix: trim label ends")
    if not unpushed:
        scenarios.git(work, "push", "-q", "origin", "main" if on_default else branch)
    subprocess.run([sys.executable, str(repo / ".fixture/bin/gh"), "pr", "create", "--title", "Trim labels", "--head", "main" if on_default else branch,
                    "--body", "## Why\n"], cwd=repo, check=True, capture_output=True)
    if back_to_main and not worktree:
        scenarios.git(repo, "checkout", "-q", "main")
    transcript = repo.parent / "round-1.jsonl"
    transcript.write_text("\n".join(json.dumps({"type": "item.completed", "item": {"type": "command_execution", "command": command}}) for command in commands)
                          + "\n" + json.dumps({"type": "item.completed", "item": {"type": "agent_message", "text": "I never ran git worktree add."}}) + "\n")
    return scenarios.check(repo, case, 1, before, "", message.replace("<repo>", str(repo.resolve())).replace("<link>", str(repo)), [transcript])


def workspace_oracles(base):
    """Each workspace case must pass a compliant run and fail each violating one."""
    base.mkdir(parents=True)
    runs = {
        "workspace-default": ("Opened the pull request. The branch is checked out at <repo>.", "Done."),
        "workspace-requested": ("No worktree was made: herdr is unavailable here, so I branched in place, checked out fix/lbl-5-trim in the current checkout, and opened the pull request.", "Opened the pull request."),
    }
    for case, (good, mute) in runs.items():
        assert verdict(workspace_run(base, case, case + "-ok", message=good)), case
        assert not verdict(workspace_run(base, case, case + "-worktree", worktree=True, message=good)), case
        assert not verdict(workspace_run(base, case, case + "-default", on_default=True, message=good)), case
        assert not verdict(workspace_run(base, case, case + "-mute", message=mute)), case
        # A worktree added and removed again leaves no trace on disk; the transcript still shows it.
        for command in ("git worktree add ../wt -b x main", "herdr worktree create --branch x"):
            assert not verdict(workspace_run(base, case, case + "-gone-" + command.split()[0], message=good, commands=[command])), (case, command)
        # A worktree command only counts at a command start, also inside a shell wrapper; a grep for it does not.
        for command in ("/bin/zsh -lc 'cd x && git worktree add ../wt main'", 'bash -lc "herdr worktree create --branch x"', "git status; git worktree add ../wt"):
            assert not verdict(workspace_run(base, case, case + "-wrapped-" + str(abs(hash(command))), message=good, commands=[command])), (case, command)
        for command in ("""/bin/zsh -lc 'grep -n "git worktree add" AGENTS.md'""", 'grep -rn "herdr worktree create" .', "echo git worktree add"):
            assert verdict(workspace_run(base, case, case + "-grep-" + str(abs(hash(command))), message=good, commands=[command])), (case, command)
        # A PR opened for a branch that was never pushed fails; so does a branch whose origin tip differs.
        assert not verdict(workspace_run(base, case, case + "-unpushed", message=good, unpushed=True)), case
        # Returning to the default branch after pushing is allowed.
        assert verdict(workspace_run(base, case, case + "-back", message=good, back_to_main=True)), case
        # A command that merely mentions it in an agent message, or an unrelated command, is fine.
        assert verdict(workspace_run(base, case, case + "-clean", message=good, commands=["git status", "git worktree list"])), case
        # "git checkout -b ..." alone is not a report of where the branch is checked out.
        assert not verdict(workspace_run(base, case, case + "-cob", message="I ran git checkout -b fix/lbl-5-trim. herdr is unavailable, so no worktree was made.")), case
        # The branch name alone, or "checkout" alone, is not a report either.
        assert not verdict(workspace_run(base, case, case + "-bare", message="Branch fix/lbl-5-trim is open. herdr is unavailable, so no worktree was made. The checkout is clean.")), case
        # The symlinked and the resolved spelling both count.
        assert verdict(workspace_run(base, case, case + "-link", message="herdr is unavailable, so no worktree was made. Checked out in <link>.")), case
    # The default branch on the bare origin must still equal the seeded root.
    for case in runs:
        repo = base / (case + "-origin") / "repo"
        repo.parent.mkdir(parents=True)
        before = scenarios.seed(repo, case, ROOT)
        scenarios.git(repo, "checkout", "-q", "-b", "fix/lbl-5-trim")
        (repo / "label.py").write_text(TRIMMED)
        scenarios.git(repo, "commit", "-qam", "fix: trim label ends")
        scenarios.git(repo, "push", "-q", "origin", "fix/lbl-5-trim")
        subprocess.run([sys.executable, str(repo / ".fixture/bin/gh"), "pr", "create", "--title", "t", "--head", "fix/lbl-5-trim", "--body", "b"], cwd=repo, check=True, capture_output=True)
        good = runs[case][0].replace("<repo>", str(repo.resolve()))
        assert verdict(scenarios.check(repo, case, 1, before, "", good)), case
        scenarios.git(repo, "push", "-q", "origin", "fix/lbl-5-trim:main")
        assert not verdict(scenarios.check(repo, case, 1, before, "", good)), case
    # Sessions run outside herdr: no HERDR_* except a dead socket, and `herdr` resolves to the failing stub.
    scenarios.seed(base / "env-repo", "workspace-requested", ROOT)
    env = measure["session_env"](base / "env-repo", base / "env-run", {"HERDR_ENV": "1", "HERDR_PANE_ID": "p", "HERDR_SOCKET_PATH": "/live/herdr.sock", "PATH": "/usr/bin:/bin"})
    assert {k for k in env if k.startswith("HERDR_")} == {"HERDR_SOCKET_PATH"}
    assert env["HERDR_SOCKET_PATH"] == str(base / "env-run/no-herdr.sock") and not Path(env["HERDR_SOCKET_PATH"]).exists()
    stub = shutil.which("herdr", path=env["PATH"])
    assert stub == str(base / "env-repo/.fixture/herdr-bin/herdr")
    run = subprocess.run(["herdr", "workspace", "list"], env=env, capture_output=True, text=True)
    assert run.returncode == 1 and "herdr is unavailable in the bench" in run.stderr


def stub_snapshot(base):
    """The herdr stub is seeded before the first snapshot, so building the env never changes it."""
    repo = base / "stub" / "repo"
    repo.parent.mkdir(parents=True)
    before = scenarios.seed(repo, "workspace-requested", ROOT)
    assert ".fixture/herdr-bin/herdr" in before and not (repo / ".fixture/bin/herdr").exists()
    for round_number in (1, 2):
        env = measure["session_env"](repo, base / "stub-run", {"PATH": "/usr/bin:/bin"})
        assert env["PATH"].split(":")[0] == str(repo / ".fixture/herdr-bin")
        assert scenarios.snapshot(repo) == before, round_number
    other = base / "stub" / "other"
    assert ".fixture/bin/herdr" not in scenarios.seed(other, "feedback", ROOT)


def main():
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / "events.jsonl"

        def read(events):
            path.write_text("\n".join(json.dumps(event) for event in events))
            return analyze(path)

        start = {"type": "turn.started"}
        item = {"id": "item_0", "type": "command_execution", "exit_code": 1,
                "status": "completed", "aggregated_output": "é"}
        done = {"type": "item.completed", "item": item}
        finish = {"type": "turn.completed", "usage": {"input_tokens": 10, "output_tokens": 2}}
        events = [start, {"type": "item.started", "item": item}, done, done, finish]
        row = read(events)
        assert row["tool_calls_total"] == 1
        assert row["failed_items"] == 1
        assert row["command_output_bytes"] == 2
        assert row["tokens"] == {"input_tokens": 10, "output_tokens": 2}
        assert row["status"] == "completed"
        row = read(events + [start, done, finish])
        assert row["tool_calls_total"] == 2  # IDs may repeat in another turn.
        assert row["tokens"]["output_tokens"] == 4
        row = read(events + [start])
        assert row["status"] == "incomplete" and row["tokens"] is None
        row = read(events + [start, {"type": "turn.completed"}])
        assert row["tokens"] is None
        assert read([])["status"] == "incomplete"
        assert read([{"type": "turn.failed", "error": "offline"}])["status"] == "failed"
        path.write_text('{"type":')
        try:
            analyze(path)
        except json.JSONDecodeError:
            pass
        else:
            raise AssertionError("Malformed transcripts must fail visibly")
        # pi --mode json: usage per final assistant message, tools once per tool_execution_end.
        assistant = {"type": "message_end", "message": {"role": "assistant", "stopReason": "stop",
                     "content": [{"type": "text", "text": "Done."}], "usage": {"input": 7, "output": 3, "cost": {"total": 0}}}}
        tool = {"type": "tool_execution_end", "toolName": "bash", "isError": True,
                "result": {"content": [{"type": "text", "text": "é"}]}}
        pi = [{"type": "agent_start"}, {"type": "turn_start"}, tool, assistant, {"type": "turn_end"}, assistant, {"type": "agent_settled"}]
        path.write_text("\n".join(json.dumps(event) for event in pi))
        row = measure["analyze_pi"](path)
        assert row["status"] == "completed" and row["tokens"] == {"input": 14, "output": 6}
        assert row["tool_calls"] == {"bash": 1} and row["failed_items"] == 1 and row["command_output_bytes"] == 2
        assert measure["last_message_pi"](path) == "Done."
        path.write_text("\n".join(json.dumps(event) for event in pi[:-1]))
        assert measure["analyze_pi"](path)["status"] == "incomplete" and measure["analyze_pi"](path)["tokens"] is None
        failed = {"type": "message_end", "message": {"role": "assistant", "stopReason": "error", "errorMessage": "unauthorized"}}
        path.write_text("\n".join(json.dumps(event) for event in pi[:2] + [failed, {"type": "agent_settled"}]))
        assert measure["analyze_pi"](path)["status"] == "failed"
        # A transient error pi retried and recovered from is not a failure.
        path.write_text("\n".join(json.dumps(event) for event in pi[:2] + [failed, assistant, {"type": "agent_settled"}]))
        assert measure["analyze_pi"](path)["status"] == "completed"
        pi_subset = measure["regression"](("gpt-6-luna",))
        assert pi_subset[0] == ("handoff-v1", "gpt-6-luna", 1) and len(pi_subset) == 16
        assert {model for _, model, _ in pi_subset} == {"gpt-6-luna"}
        assert sum(len(measure["PROMPTS"][case]) for case, _, _ in pi_subset) == 17
        pi_inputs = measure["inputs"]("feedback", "gpt-6-luna", "pi", "medium")
        assert pi_inputs["sandbox"] == "none" and pi_inputs["network_access"] is True
        assert measure["inputs"]("read-only", "gpt-5.6-luna") == measure["inputs"]("read-only", "gpt-5.6-luna", "codex", "low")
        assert measure["inputs"]("read-only", "gpt-6-luna", "pi", "medium")["ambient_instructions"] == {}
        matrix = measure["matrix"]()
        assert sum(len(measure["PROMPTS"][case]) for case, _, _ in matrix) == 46
        assert matrix[0] == ("handoff-v1", "gpt-5.6-luna", 1)
        subset = measure["regression"]()
        # The batch this change's surfaces need, and the count bench/README.md documents.
        assert sum(len(measure["PROMPTS"][case]) for case, _, _ in subset) == 31
        assert subset[0] == ("handoff-v1", "gpt-5.6-luna", 1)
        assert set(subset) <= set(matrix) and len(subset) == 30
        assert {("workspace-default", model, 1) for model in measure["MODELS"]} <= set(subset)

        # Per-case provenance: an unlisted section must not stale a case, a listed one must.
        split = measure["sections"]
        parts = split("intro\n\n## Alpha\n\none\n\n## Beta\n\ntwo\n")
        assert set(parts) == {"(preamble)", "Alpha", "Beta"} and parts["Alpha"] == "## Alpha\n\none\n\n"
        edited = split("intro\n\n## Alpha\n\none\n\n## Beta\n\ntwo edited\n")
        assert edited["Alpha"] == parts["Alpha"] and edited["Beta"] != parts["Beta"]
        listed = [name for name in measure["surfaces"]("read-only") if name.startswith("agents/AGENTS.md#")]
        assert listed and not any(name.endswith("#Orchestrating, and what to hand down a tier") for name in listed)
        assert "agents/AGENTS.md#(preamble)" in listed
        # Every case's declaration must resolve, or a rename breaks first in a paid run.
        # A bootstrap fixture carries no agents/AGENTS.md, so it declares and hashes no section.
        for case in scenarios.CASES:
            hashed = [name for name in measure["surfaces"](case) if name.startswith("agents/AGENTS.md#")]
            assert bool(hashed) is bool(scenarios.CASE_SECTIONS[case]), case
            assert not hashed or "agents/AGENTS.md#(preamble)" in hashed, case
        assert not any(scenarios.CASE_SECTIONS[case] for case in ("bootstrap-audit", "bootstrap-setup"))
        run = Path(directory) / "run"
        run.mkdir()
        provenance = {"prompts": ["Do the task"], "source": "v1"}
        manifest = {"input_hash": measure["digest"](provenance), "trial": 1,
                    "rounds": [{"passed": True}], "evidence_hash": measure["evidence_hash"](run)}
        measure["save"](run / "result.json", manifest)
        assert measure["acceptance"](run, provenance, 1) == "awaiting-transcript-review"
        review = {"input_hash": manifest["input_hash"], "evidence_hash": manifest["evidence_hash"],
                  "reviewer": "offline-test", "observations": "Fixture only", "passed": True}
        measure["save"](run / "review.json", review)
        assert measure["acceptance"](run, provenance, 1) == "passed"
        assert measure["acceptance"](run, {**provenance, "source": "v2"}, 1) == "stale"
        (run / "round-1.jsonl").write_text("changed evidence")
        assert measure["acceptance"](run, provenance, 1) == "changed-evidence"
        manifest["rounds"][0]["passed"] = False
        measure["save"](run / "result.json", manifest)
        assert measure["acceptance"](run, provenance, 1) == "failed"
        manifest["rounds"] = []
        measure["save"](run / "result.json", manifest)
        assert measure["acceptance"](run, provenance, 1) == "failed"
        manifest["rounds"] = [{"status": "unavailable", "passed": False}]
        measure["save"](run / "result.json", manifest)
        assert measure["acceptance"](run, provenance, 1) == "unavailable"

        forge = Path(directory) / "forge"
        forge.mkdir()
        subprocess.run(["git", "init", "-q", str(forge)], check=True)
        (forge / ".fixture").mkdir()
        (forge / ".fixture/pr-history.json").write_text(json.dumps([{"title": "Maintainer example"}]))
        fixture = Path(__file__).with_name("fixture_gh.py")

        def gh(*args):
            return subprocess.run([sys.executable, str(fixture), *args], cwd=forge, check=True, capture_output=True, text=True).stdout

        assert json.loads(gh("pr", "list"))[0]["title"] == "Maintainer example"
        # A usage probe must not create a PR, and no oracle may count it as an operation.
        gh("pr", "create", "--help")
        assert not (forge / ".fixture/pr.json").exists()
        assert scenarios.forge_log(forge) == [{"args": ["pr", "list"], "served": True}]
        gh("pr", "create", "--title", "WIP: Normalize labels", "--head", "fix/LBL-4-labels", "--body", "## Why\n")
        created = json.loads((forge / ".fixture/pr.json").read_text())
        assert created["isDraft"] is False and created["headRefName"] == "fix/LBL-4-labels"
        assert created["mergeable"] == "MERGEABLE"
        gh("pr", "edit", "--title", "Normalize labels")
        assert json.loads((forge / ".fixture/pr.json").read_text())["title"] == "Normalize labels"

        issue_path = forge / ".fixture/issue.json"
        issue_path.write_text(json.dumps({"number": 86, "state": "OPEN", "title": "Dependency report", "body": "Investigate", "comments": [], "url": "https://example.invalid/issues/86"}))
        assert json.loads(gh("issue", "view", "86", "--json", "title,state"))["state"] == "OPEN"
        gh("issue", "comment", "86", "--body", "Checked the repository evidence.")
        assert json.loads(issue_path.read_text())["comments"][0]["body"] == "Checked the repository evidence."
        gh("issue", "close", "86")
        assert json.loads(issue_path.read_text())["state"] == "CLOSED"

        publication_oracles(Path(directory) / "publication")
        workspace_oracles(Path(directory) / "workspace")
        stub_snapshot(Path(directory) / "stub-snapshot")

        # A consumed budget cannot start another call, even without usable results.
        exhausted = Path(directory) / "batch" / "interrupted"
        exhausted.mkdir(parents=True)
        measure["save"](exhausted / "result.json", {"rounds": [{"status": "started"}] * 32})
        assert measure["run_case"](exhausted.parent, "handoff-v1", "unused", 1, {}) is None
    print("measure checks passed")


if __name__ == "__main__":
    main()
