# bench

Harness performance measured from real Claude Code sessions, not synthetic tasks. Every session already leaves a deterministic record under `~/.claude/projects/`, and every harness change has a commit date in this repo, so validating a change means splitting the real session population at that date and comparing, per cohort.

A synthetic task battery lived here first and was removed after one day: its control tasks swung 4x between identical runs, the tasks contaminated their own fixture (the repo), and the pinned cheap model failed tasks the real models pass. Real sessions have none of those problems, at the cost of arriving slowly and mixing many variables; both approaches judged, this one loses less.

## Usage

    bench/measure <session-id|jsonl>                 one session, full JSON
    bench/measure --all [--since D] [--until D]      one JSONL row per session
    bench/measure --report [--since D] [--split D]   aggregate by cohort

`--split <date>` is the before/after: set it to the commit date of a harness change and compare the medians. `bench/cohorts.json` (gitignored; copy `cohorts.example.json`) lists the transcript roots to sweep and the directory patterns that mark the work cohort; everything else is personal. It stays out of the repo because it names accounts and employers. A root owned by another account is reported and skipped rather than read, so a sweep across accounts runs from the account that owns the data.

## What a row carries

Cost: output tokens, cache reads, tool calls by name, wall minutes, tool-result bytes. Friction, which is the part synthetic tasks cannot see: `interrupts` (the user stopped a running turn), `denials` (a permission rule blocked a call), `error_results`, and `sidechain_messages` (subagent delegation, counted from the `<session-id>/subagents/*.jsonl` sidecar files; the inline `isSidechain` flag stopped appearing, so before that fix this read 0% and the "no delegation" conclusion drawn from it was a measurement artifact). `commands` counts slash-command invocations, so routing adoption is visible over time.

## Caveats, honestly

Sessions are not controlled experiments: a hard week moves every number without the harness changing. Read `--split` comparisons as populations, not pairs; require a real gap, not a nudge; and never read a single session as evidence of anything. Outputs contain project names, so aggregate output is fine to share and `--all` rows are not; nothing here writes files, so nothing sensitive can be committed by accident. Quality remains a human judgment made by reading sessions, not a number this tool produces.
