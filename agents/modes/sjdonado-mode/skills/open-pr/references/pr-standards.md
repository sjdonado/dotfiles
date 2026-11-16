# PR structure and quality gates

Read the target repository's current template and PR standards from disk on every creation or refresh, including host-owned publication. Select its applicable template when several exist. Those files own project headings, validators, labels, rollout metadata, and required checks. This reference owns the personal defaults; do not copy a second standards document into the project.

If the project defines no template or body structure in its instructions, start the temporary body from `assets/pull_request_template.md`, relative to the open-pr skill directory. Use the asset without installing it into the repository unless the user requests that change. Its required headings are Summary, Reviewer notes, Verification, and Demo, in that order. Optional sections may be deleted. A project-defined equivalent structure takes precedence; preserve its heading order and parser-sensitive names. Resolve a conflict that prevents required evidence from being represented rather than silently omitting it. Record the chosen structure for the delivery checker.

## Quality gates before publication

Apply principle-prove-it-works to the complete accepted scope, not just the latest diff. Select and execute the relevant coverage before committing, pushing, PR creation or a ready-to-publish host handoff:

- Every PR: run the repository's applicable required checks. For prose-only changes, inspect the edited artifact and its relevant references; do not invent an application build or screenshot requirement. A pre-existing failure is evidence to investigate and report, not a passing check or an automatic waiver of a required gate.
- Changed user-facing behavior, a production bug, shared code, or a project-designated critical path: exercise the real affected entry point, the main journey and relevant edge cases. Capture visible behavior as specified in demo.md. Project checks alone do not replace this exercise.
- Multiple affected flows, architectural changes to shared infrastructure, or a critical change whose impact exceeds the main journey: trace the affected consumers and exercise their relevant journeys and failure paths. Use blast-radius for compatibility boundaries. Name the flows and consumers covered; the size of the diff alone cannot establish coverage.

These are coverage scopes, not requirements to add tests or commission an independent review on every PR. Use the project's peer-test or QA labels when it defines them. Reuse valid evidence; invalidate only results affected by subsequent changes. An unavailable required check or promised behavior blocks publication under the existing evidence gate. A draft, unattended run, or human-readable Not verified note does not waive it. Report unrelated limitations truthfully without presenting them as passing results.

## Write for the reviewer

Use the project's title convention; otherwise use a concise Conventional Commit title. Explain the concrete problem and resulting behavior in two or three summary sentences. Follow with real `Resolves <ID>` or `Refs <ID>` lines under the shared ticket rules, without inventing a ticket. With supported rendering, add a fenced Mermaid diagram immediately after those lines when three or more components, a process boundary, or a state machine make the approach easier to assess visually. Keep it about 15 lines or fewer; skip it when the summary already explains the change.

Keep the overview before Details to roughly one screen (about 25 rendered lines, excluding media and useful diagrams). Move mechanism, measurements, history, rejected findings, assumptions, manual steps, and long verification into separate collapsed `<details>` blocks. Follow the repository's structure when it differs rather than forcing these literal headings.

Reviewer notes contain only decisions or actions that matter, most important first:

- **Decide:** an in-scope decision, its alternative, and what the reviewer can change.
- **Risk:** what can break, who is affected, and any migration, compatibility, deploy-order or rollout constraint.
- **Not verified:** the specific unverified claim and missing prerequisite; required gaps still block publication.
- **Tests:** what added or changed tests cover and why their boundary is appropriate.
- **Check:** one or two useful reviewer actions and where to try them.

Write `None.` when no notes apply. In unattended work, expose consequential in-scope assumptions here; do not treat the lack of a person to ask as authority to decide unresolved product scope or publish unverified work.

Verification contains at most five concise lines, each labelled **Executed** or **Static** according to principle-prove-it-works. Name the gate trigger when useful, command or interaction, environment/build, and observed facts or counts. Link accessible runs and previews. Put longer evidence in a Full verification record block. Do not classify unit, lint or source checks as application runtime evidence.

Keep a Demo section in the fallback, including a concrete `n/a` reason for nonfunctional changes. For functional changes, demo.md defines the evidence by change type and delivery-evidence.md defines the gate; a generic `n/a: no UI change` does not replace a reproducible nonvisual demonstration. Each media item needs a caption naming its scenario and environment/build. Show at most six items inline and collapse the rest. Upload only through a supported, authorized attachment mechanism and confirm that the reviewer or receiving host can access the result; local files or expiring private links are not delivered media.

Add a feature flag only when requirements explicitly request one. Record any flag that actually gates the change, including widened use of an existing flag. Keep a flag section when the project requires it, using exact keys/URLs or `none` as its parser expects; otherwise omit an irrelevant section. A missing request for a flag is not a reason to ask for one. Use only project-defined labels and stack tooling. Do not import another project's providers, deployment labels, database commands or automation.

Release notes, when applicable, are one user-readable sentence. Delete empty optional sections. Keep only applicable completed checklist items, and also surface consequential checklist risks in Reviewer notes. Resolve review conversations only within separately authorized review work; publication authority alone does not authorize messages or merges.
