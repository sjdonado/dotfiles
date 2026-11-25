# Shared agents and opt-in development

The shared policy in AGENTS.md carries common safeguards, authority, and one development-mode activation trigger. Ordinary requests and personal-agent sessions do not inherit the development workflow, writing preferences, or review procedures.

## Activate development mode

In T3 Code, begin the development task with `sjdonado-mode:` or explicitly invoke the sjdonado-mode skill through the active provider. A trusted development orchestrator can instead give a worker the absolute path of modes/sjdonado-mode/MODE.md and explicitly direct it to read and follow that mode for its assigned task. Merely mentioning the mode in a ticket, document, or quotation does not activate it.

The mode lasts for one task, including its feedback turns. A new task or explicit exit ends it. Invocation chooses how to work; a local task stays local unless publication is requested. An opened-PR outcome and a green-PR outcome have different stopping conditions. Neither permits merging.

One entry point routes investigation, review, prototypes, implementation, and requested delivery to private playbooks. Feedback continues the current task and stage. Prototypes get cheap useful checks with deferred work named honestly. Before a fix or delivery claim, the final accumulated change needs evidence for its actual behavior, failure paths, and required project checks. Type checks and worker summaries alone cannot establish runtime correctness.

## Layout and ownership

- AGENTS.md owns shared safeguards and activation only.
- skills/sjdonado-mode/SKILL.md is the thin entry point. Claude's disable-model-invocation flag and Codex's agents/openai.yaml policy prevent implicit selection.
- modes/sjdonado-mode/MODE.md owns routing, scope, and task lifetime.
- modes/sjdonado-mode/playbooks/ owns task procedures. Review repair and iterative feedback are steps of the mode, not separately invoked workflows.
- modes/sjdonado-mode/skills/ owns local principles and helpers, including open-pr as the sole publication procedure and principle-prove-it-works as the owner of verification stages.
- modes/sjdonado-mode/vendor/pstack/ holds a deliberately selected, pinned public subset with its upstream license and provenance in ORIGIN.md. Imported metadata is inert until read by the mode; local verification and host instructions govern its use.
- skills/ exposes the sjdonado-mode entry point and standalone skills such as feature-map. Mode helpers resolve under its private skills/ directory or vendor subset. MODE.md gives explicit paths for overlaps.

Private resources must remain outside all discovered skill roots. A nested folder beneath skills/ would still expose private leaves to hosts that recursively discover skills. Do not symlink modes/ or private leaf directories into a discovery root.

## Installation and tool access

setup/lib/links.sh owns the shared policy and skill links for supported hosts. The existing links expose skills/, while the entry point resolves its source symlink before following the relative path to modes/. No host provisioning or new scheduler is needed for the mode split. The host's current tool instructions take precedence over generic operation examples.

Use T3 for development orchestration, delegation, workspace binding, and PR watches. Keep provider binaries and configuration needed by T3, without invoking them as separate terminal workflows. Keep personal or account-specific tool configuration outside public mode resources.

## When to run evals

Run focused harness evals when changing shared policy, mode activation, routing, playbooks, helper skills, authority, continuity, delegation, review, or verification decisions. Also run the relevant case when an observed agent failure challenges an existing rule or exposes missing coverage. Select by the changed decision, not file count or PR existence.

Routine project changes use that project's checks. Wording or path changes that preserve instruction behavior need structural and reference checks; they do not automatically require new model sessions. Provisioning changes use setup/verify/ separately. Do not rerun unaffected cases or treat old observations as proof of changed instructions.

The procedure, area index, safe fixtures, and recorded observations live under eval/. Start at eval/README.md for how to select and run a case.

## Public principle updates

The private pstack subset is maintained as a deliberate vendored import. Import only required leaves and their dependencies at one revision, preserve the MIT notice, record source URLs and file hashes in its ORIGIN.md, and validate references. Do not import upstream autonomy grants, model ids, host-specific orchestration, or shipping rules as implicit policy. The source is https://github.com/cursor/plugins/tree/main/pstack.

Major setup decisions and lessons live in the repository's adrs/ directory. These records preserve reasoning, alternatives, and material consequences; they are not specifications, task checklists, or merge gates. Routine edits need no record. Personal writing guidance retains the existing adaptation from https://github.com/JuliusBrussee/caveman (MIT, commit 600e8ef), scoped to the development mode.
