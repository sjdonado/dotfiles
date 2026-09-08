"""Offline regression checks for real-event accounting, no model calls."""

import json
from pathlib import Path
import runpy
import tempfile

analyze = runpy.run_path(str(Path(__file__).with_name("measure")))["analyze"]


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
    print("measure checks passed")


if __name__ == "__main__":
    main()
