---
name: evidence
description: Challenge a load-bearing claim with production data instead of asserting it. Defines the falsifiable-prediction protocol, the kill query, a capability-based source map, query budgets, and the no-fabrication guard. Use when triaging, researching, drafting a ticket, or checking whether a plan's premise still holds.
---

# Evidence

The point is not to decorate a document with numbers. It is to find out you are wrong before you write code.

## What deserves a query

Only a **load-bearing** claim: one where being wrong changes whether the work happens, what its scope is, or where the fix goes.

If a claim is not load-bearing, say nothing about it. Do not gather evidence to look thorough.

## Challenge protocol

For each load-bearing claim, write it as a falsifiable prediction **before** querying. The prediction must be one the data could actually refute.

- Not "this error affects users" (unfalsifiable) but "this error fires more than 10 times a day and has fired since the deploy of `<sha>`".
- Not "this endpoint is slow" but "p95 of `<endpoint>` exceeds 2s over the last 7 days".

Then query, then record a verdict:

- **confirmed**, with the number
- **refuted**, with the number
- **no data**, when the source has nothing or the signal is not instrumented

**A refuted verdict must change the output**, on its own line: dropped scope, a closed ticket, a different root cause, a smaller fix. If refuting a claim leaves the recommendation unchanged, the claim was not load-bearing. Delete it.

## Kill query first

Before investigating how to fix something, run the one query that could make the work unnecessary:

- Is the error still occurring after the most recent deploy?
- Does any non-test user actually reach the affected step?
- Is the slow path ever called?

Report a kill result loudly. "Zero occurrences in 30 days" outranks any amount of code analysis.

## Source map, by capability

Name tools as server plus bare tool name, per `AGENTS.md`. Skip a capability entirely when the project has none configured; that is a normal state, not a blocker.

- **Error tracking.** Issue search for frequency, first seen, and last seen. Event aggregation for counts grouped by release or environment, and for timeseries. Issue detail for the stack. Automated root-cause analysis is a **hypothesis to verify in code**, never a finding on its own.
- **Product analytics.** Affected-person counts and funnel step conversion. Session replays when the claim is about what a user actually saw or did; one replay confirming the reproduction outranks inference from event counts. Respect the project's test-account filtering. Where person properties are recorded at ingest time rather than queried live, never write a query whose conclusion depends on a person's current property value.
- **Metrics, logs, and traces.** Rate and percentile latency from metrics. Log search for confirmation and for failure modes that were never instrumented as errors. Trace search for where the time actually goes. Incident and alert history for whether this has paged before. Always produce deep links with the tool's own link generator; never hand-assemble a dashboard URL.
- **Database.** Confirm a table, column, or constraint exists before asserting it. Row counts for blast radius. Advisors for security and performance warnings touching the changed surface. Migration history before proposing a migration.
- **Tracker.** Search for prior art before treating something as new. Duplicate detection is evidence.
- **Version history.** `git log` and `git blame` for when a behavior changed and what shipped alongside it; release or deploy history to correlate a telemetry inflection with a commit range; PR discussion as prior art on why the code is the way it is. A regression claim ("this got slower recently") is checked against history the same way an impact claim is checked against telemetry.

## No-fabrication guard

Every number carries its source deep link and its timeframe, both as complete absolute URLs.

- Never state a number you did not read from a tool result.
- Never widen a timeframe to make a number look bigger, or narrow one to make it look smaller.
- If a source returns nothing, write `no data in <source> for <window>` rather than omitting the claim. Silence reads as absence of impact.
- If a query fails or times out, say so. Do not substitute an estimate.
- Never infer an affected-user count from an error count, or an error rate from a sample.

## Budget

About three queries per claim, about ten per session.

If three queries have not settled a claim, it is not answerable from telemetry: mark it `no data`, state what instrumentation would answer it, and move on.

Never dump a raw query result into the output; report the number, the window, and the link. Never page through more results looking for a bigger number.
