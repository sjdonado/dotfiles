## Purpose

Evaluate workflow correctness and continuation independently of model self-reports, with bounded, reproducible evidence for future efficiency comparisons.

## ADDED Requirements

### Requirement: Discoverable project verification

The repository's root AGENTS.md SHALL map applicable changes to executable verification commands and explain their prerequisites and effects. Verification SHALL separate deterministic tooling checks from behavioral acceptance. Missing required behavioral results SHALL not be reported as passing, and unchanged evidence SHALL be reusable only when its recorded inputs match the current configuration.

#### Scenario: Fresh agent validates a harness change

- **WHEN** a fresh agent follows the repository instructions without conversation or worktree state
- **THEN** it can discover the applicable local and behavioral checks and cannot mistake local tooling success for completed harness acceptance

#### Scenario: Behavioral result is absent or stale

- **WHEN** required coverage is absent or its harness, skill, scenario, or model inputs differ
- **THEN** behavioral verification reports incomplete acceptance with a nonzero exit instead of reusing an unrelated success

#### Scenario: Project guidance skill is evaluated

- **WHEN** audit and setup/repeat scenarios run against ordinary project fixtures
- **THEN** independent checks verify read-only audit, grounded commands, preservation of scoped instructions, absence of personal workflow dependencies, and repeat-application stability

### Requirement: Independent outcome checks

Each benchmark scenario SHALL declare its expected artifacts, allowed writes, and terminal outcome before execution. The runner SHALL judge those expectations independently of assistant claims and retain every attempt, including failed and incomplete attempts. A blocked-for-input outcome SHALL count as correct when the scenario intentionally omits an essential requirement.

#### Scenario: Confident but wrong completion

- **WHEN** the model reports success but the artifact contradicts the supplied requirement
- **THEN** the scenario fails even if the model's own tests passed

#### Scenario: Correct clarification

- **WHEN** the required behavior is deliberately absent and the model asks for it without dependent edits
- **THEN** the missing-contract scenario passes rather than penalizing the clarification

### Requirement: Transition coverage

The benchmark SHALL exercise fresh-session continuation, unrecoverable context, read-only plain-language routing, PR-update ownership, and no-OpenSpec landing. Continuation sessions SHALL not receive the prior conversation. External workflow scenarios SHALL use disposable local substitutes and SHALL not write to a real forge or tracker.

#### Scenario: Branch note is the only surviving rationale

- **WHEN** a fresh session receives a continuation request
- **THEN** the original deferred behavior and rationale survive through the intended artifact, not through prompt repetition or access to saved benchmark answers

### Requirement: Bounded cross-model reporting

Evaluation SHALL record exact scenario and harness versions, model settings, usage when reported, and per-scenario outcomes. It SHALL distinguish smoke-test acceptance from general reliability or efficiency claims and SHALL report unavailable model configurations as untested without substituting silently.

#### Scenario: Comparing effectiveness

- **WHEN** the same scenario runs against different harness versions
- **THEN** the report retains failures, compares correctness first, and separates tokens and tool counts by model and successful outcome

#### Scenario: Insufficient evidence

- **WHEN** only a smoke sample exists or no matching baseline was run
- **THEN** the report makes no universal-model or token-savings claim
