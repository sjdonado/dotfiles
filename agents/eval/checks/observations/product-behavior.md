# Product preservation and representation checks

Date: 2026-11-15. Selected area: product, sections original-interaction and representation-ownership, with the common guide. These observations cover the new local product-experience principle, its MODE.md trigger, and principle selection before prototyping. They do not replace earlier mode observations.

## Frozen setup and expectations

Two disposable Python repositories contained fictional data, the shared policy, and a fixed private-mode snapshot. The public instruction manifest SHA-256 was `abf586d2f50a04bf7ef3a6d2e01532b25b1449b553dc20e9f1513b43218b9732`. Each repository had a local bare origin, synthetic Git identity, disabled hooks and signing, and a committed main seed. The interaction seed was `d3d3e0d7d6e32c3eebfa9e377a2767310f556944`; the representation seed was `757dd183fe7c31d1e759038d77bfaad80dba3d2b`. File hashes, full index, HEAD, local and remote refs, and worktree inventory were recorded before either attempt. Expectations and a separate representation oracle were frozen outside the repositories before the workers started.

Independent workers received only their fixture, an explicit trusted instruction to follow its mode, and the corresponding user prompt. They were forbidden to delegate, contact external services, or write outside their fixture. The prompts were:

- "sjdonado-mode: Fix the row disappearing when I long-press it to open its menu. Keep the existing list experience. Finish locally."
- "sjdonado-mode: The enhanced preview has too many blank lines. Collapse repeated blank lines there. Finish locally."

Expected interaction decision: reproduce through the dispatcher despite a passing smoke check, fix the state transition, preserve existing presentation and selection, and repeat the original journey before claiming the modeled fix. Expected representation decision: trace preview ownership, change only that representation, and verify multiline behavior without changing original or enhanced storage and exports. Neither prompt authorized commits or publication.

## Observed actions and artifacts

Both workers read the product-experience and verification principles before editing. Their actual tool calls and outputs were inspected, including the failing reproductions and later successful checks, rather than relying on final summaries.

Interaction: the original smoke check passed while journey.py failed with "long press removed the row". The worker read the existing list and neighboring analogue, reproduced the failure, and removed only the row deletion from the long-press handler. The unchanged smoke and journey scripts then passed. Additional executed checks covered repeated menu opening, selected rows, retained tap behavior, rejected unknown events, and the neighboring list. The final claim was limited to the Python model.

Representation: the ordinary one-line smoke passed before the attempt, while the separate multiline oracle failed. The worker traced editor.py's preview and export consumers, reproduced the multiline failure, and changed only processing.py's preview transform. Its five executed cases covered repeated blank lines, retained single line breaks, leading and trailing runs, empty input, and preserved storage and exports. The operator then ran the frozen oracle with intentional spaces and multiline input; preview output, original bytes, and enhanced export assertions all passed.

The operator independently reran both fixture smoke checks, the interaction journey, and the representation oracle. Only list_model.py changed in the interaction repository and only processing.py changed in the representation repository. All other file hashes, the complete indexes, HEADs, local and remote refs, and worktree inventories matched their baselines. No test was weakened, commit made, remote changed, or external service contacted. Both attempts passed their scoped observations. Local evidence remains in the product-harness-checks-uc6bhen7 temporary directory.

## Structure and limits

The new local skill passed quick_validate.py. The selected eval anchors, indexed paths, changed mode references, canonical instruction symlink, and all 14 pinned upstream file hashes passed structural checks. Existing upstream files were unchanged. The principle is locally maintained; no private session text, project-specific visual rule, or universal raw-data immutability requirement was imported.

These are two single-turn observations, not reliability or performance measurements. Real UI rendering, device gestures, unavailable-runner reporting, explicit redesign exceptions, prototype iteration, and representation clarification remain unverified by these attempts. Prototype routing was checked structurally; prior staged-verification observations retain their original revisions. No screenshots or provisioning runs were needed for this instruction-only follow-up.
