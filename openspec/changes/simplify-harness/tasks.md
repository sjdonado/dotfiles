# Tasks

## 1. Harness behavior

- [x] 1.1 Replace mandatory routing with capabilities and explicit autonomy in agents/AGENTS.md; verify behavioral scenarios distinguish plan approval from autonomous delivery.
- [x] 1.2 Simplify workflow skills, review selection, verification, tests, delegation and continuity; validate frontmatter and search for stale mandatory rules.
- [x] 1.3 Update agents/README.md, the repository guide and existing OpenSpec artifacts to match the approved behavior; run openspec validate simplify-harness --strict.

## 2. macOS preferences and shared tools

- [x] 2.1 Finish the Handy preferences link and account-local onboarding behavior; validate JSON, shell syntax and verify/macos.sh without host activation.
- [x] 2.2 Add mise to the shared Nix packages and existing assertions; run macOS and disposable Linux setup checks, recording unavailable platforms as unverified.

## 3. Behavioral evidence

- [x] 3.1 Update existing scenarios and cover the observed small-change, snapshot, explicit-autonomy and review-selection gaps; replace provider launchers with direct gpt-6-luna subagent benchmarks and local fixture helpers.
- [x] 3.2 Send the relevant benchmark prompts to gpt-6-luna subagents and inspect every tested turn and artifact; record final results and remaining limitations without editing generated evidence.

## Retained work

The branch already extracted the principles and reusable worktree/open-pr steps, renamed proto to iteration, removed git-bug-mcp and added git-bug CLI support. Keep those delivered capabilities while replacing the mandatory lifecycle.

## Workflow follow-up

- Publish only on the user's request; keep the local batch on the existing PR branch.
- Archive through land after a verified merge, never during implementation.

## Verification evidence

- Local validation: 18 edited skills pass quick_validate; OpenSpec strict validation and git diff --check pass.
- Setup: verify/macos.sh reports 57 passed, 0 failed, including the Handy links and mise declaration. Package assertions cover 104 macOS packages and 27 packages for each Linux architecture, with no collisions. No host activation occurred.
- Linux provisioning remains unverified: the OrbStack Docker context is missing and the default socket denies access. This does not count as a passing Linux provisioning run.
- Benchmark wiring: all 10 fixtures prepare with the local helper; all YAML files parse without duplicate mappings. The helper no longer launches providers or parses provider sessions.
- Direct gpt-6-luna outcomes: the small config change touched only the requested value, plan-only then local implementation preserved publication boundaries, the red-check PR gate passed 8 assertions and its green continuation passed 12, explicit autonomous delivery passed 16 assertions including worktree isolation, and local feedback beside a staged preference snapshot passed 11, followed by 19 assertions for its scoped publication continuation. These are targeted behavioral observations, not a performance benchmark or exhaustive model guarantee. Earlier Pi-run evidence remains ignored and unedited; it is superseded by the direct-subagent method.
