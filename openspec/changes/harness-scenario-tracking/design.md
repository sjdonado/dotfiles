# Design

## Context

See proposal.md for the purpose and scope. The legacy benchmark retains disposable repositories, a local bare origin, a forge substitute and hash-bound transcript reviews. The new slice keeps those evidence boundaries but moves scenario declarations out of Python into JSON. Pi is an existing eval driver, not a daily harness or a component to update in this change.

## Goals / Non-Goals

**Goals:**

- Keep the runtime small: parse JSON, copy and seed a fixture, invoke Pi, collect measurements, then call the declared assertion files.
- Make task correctness independently checkable from Git/forge state and actual executed tools.
- Compare models without changing prompts, fixture semantics or acceptance assertions.

**Non-Goals:**

- No full legacy-matrix port, general multi-turn framework, new grading service, new package or dependency lockfile.
- No daily-harness MCP configuration, code-mode rollout, Pi update or Pi Durable implementation.
- No reliability or token-savings claim from one successful smoke run.

## Decisions

- JSON is the scenario source. Keep the small provider/test/assertion shape already explored rather than add a DSL. Prompts, fixture paths, model settings and assertion paths belong in declarations; generic execution belongs in TypeScript. Adding a comparable case should require configuration and a fixture/check, not another runner branch.
- Bun and standard-library modules are enough. Reuse the installed Pi CLI and its existing isolation flags; do not add a provider SDK or require an API key to migrate the scenario format.
- Each attempt has a separate retained directory, fixture repository and local bare origin. Current instructions replace frozen copies at execution time. Input hashes include the scenario, execution code, assertion code, fixtures and materialized instructions; exact version, command and settings accompany the result.
- Artifact assertions judge commits, remote refs, forge operations and posted bodies. Required skill reads come from executed tool events, not a prompt mentioning the path. Provider errors and incomplete turns cannot pass even when Pi exits zero. Unsupported declarations fail visibly instead of silently weakening acceptance.
- Usage and wall time are measurements, not success criteria. Report missing usage as unknown and review pass rates before token or latency figures. Do not pool scenarios or models. Deterministic tests cover both compliant and violating artifacts before paid runs.
- The planning/code/planning probe reuses the legacy fresh-process rounds. A second multi-turn engine is not needed for one phase-boundary regression. Transcript review assesses tradeoffs and activation meaning that keyword checks cannot establish.

## Risks / Trade-offs

- Pi is not sandboxed. Use only disposable fixtures, local remotes, invalid forge credentials and the explicit forge substitute. Keep user instructions, settings and extensions out of the temporary agent directory; credential handoff is an opaque link, never inspected by the runner or agent. This is not a security sandbox and the PR must not describe it as one.
- A new runner can accidentally accept a terminal success claim without side effects. Offline negative tests and retained operation logs must prove that such claims fail.
- The first slice does not cover the whole old matrix. Retire only rows with demonstrated parity; keep the remaining coverage and failed evidence visible.
- Editing hashed inputs stales earlier acceptance. Final validation must refer to the exact sources submitted, and transcript reviews must match the evidence they judge.

## Migration Plan

1. Run free TypeScript and legacy tooling checks.
2. Run the four JSON scenarios on both pinned models and the applicable retained legacy regression through unchanged Pi.
3. Review every transcript, including failures, before deciding parity. Record which overlapping cases move to the JSON slice and which remain on the legacy path.
4. Publish the verified slice and instruction coherence fixes on the existing task branch. Leave the PR open for human review; archive only after merge.

The user explicitly chose to publish this eval-tooling scope with documented legacy behavioral failures. Local tooling success and a completed model run are not behavioral acceptance. Retain and report those failures; do not expand this PR into inherited harness fixes or retire overlapping legacy coverage without parity.

## Deferred Work

Continue direct MCP use. Revisit code mode for Claude, Codex and OpenCode when the cross-client approach is mature enough to assess. Explore the user-named Pi Durable topic separately later. Neither topic changes this PR's acceptance or authorizes configuration work.
