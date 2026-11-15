---
name: benchmark-checklist
description: Validate a measured performance claim before using it to choose an implementation or report a speedup.
---

Before measuring, state the claim, workload, metric and timed region. Inspect the measurement code: what starts the clock, what ends it, and what work or failures it omits.

1. Make the comparison fair. Record versions, build mode, data, concurrency, resource limits, background load and cache state. Use representative settings on both sides. If a relevant setting is untuned or conditions cannot be matched, report that limitation rather than picking a winner.
2. Confirm the work happened inside the timed region. Await completion, consume lazy results, count failures and retries, and check output correctness. A fast rejection or skipped workload is not a speedup.
3. Diagnose the limiting resource in a separate profiling run. Check the workload driver as well as the target. Do not report profiler-instrumented timings as ordinary performance. Check that the claimed gain is plausible given the time the changed component occupied.
4. Run repeated trials with alternating sides so warmup and drift favor neither. Start with at least five trials per side for a comparison; report run count, median and variation. A gap within run-to-run noise is no measurable difference. Increase sampling only when it could resolve the decision.
5. Measure the user-visible path with realistic sizes and concurrency beside a microbenchmark. State the changed component's share of the whole; a local improvement does not establish an end-to-end gain.

For a quick ballpark explicitly requested by the user, one run is sufficient if labeled as one run. Still confirm successful outputs and actual work; do not use that shortcut to choose between alternatives.

Report faster, slower, no measurable difference or inconclusive, with units, workload, run count, variation, limiting resource and evidence location. Mark the claim inconclusive when conditions are not comparable, correct completion is unverified, or the proposed explanation has no measured support. Keep the measurement artifacts needed to reproduce the result; never convert a target or estimate into a measured value.
