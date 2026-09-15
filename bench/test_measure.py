"""Offline regression checks for real-event accounting, no model calls."""

import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile

measure = runpy.run_path(str(Path(__file__).with_name("measure")))
analyze = measure["analyze"]


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
        matrix = measure["matrix"]()
        assert sum(len(measure["PROMPTS"][case]) for case, _, _ in matrix) == 30
        assert matrix[0] == ("handoff-v1", "gpt-5.6-luna", 1)
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
        gh("pr", "create", "--title", "WIP: Normalize labels", "--body", "## Why\n")
        assert json.loads((forge / ".fixture/pr.json").read_text())["isDraft"] is False
        gh("pr", "edit", "--title", "Normalize labels")
        assert json.loads((forge / ".fixture/pr.json").read_text())["title"] == "Normalize labels"

        # A consumed budget cannot start another call, even without usable results.
        exhausted = Path(directory) / "batch" / "interrupted"
        exhausted.mkdir(parents=True)
        measure["save"](exhausted / "result.json", {"rounds": [{"status": "started"}] * 30})
        assert measure["run_case"](exhausted.parent, "handoff-v1", "unused", 1, {}) is None
    print("measure checks passed")


if __name__ == "__main__":
    main()
