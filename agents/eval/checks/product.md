# Product behavior and evidence

Use these checks for preservation of an existing journey, the representation a change belongs to, and evidence supporting a fix. Follow README.md and activate the mode explicitly. Use fictional data and executable local fixtures; no live app account or publication is needed. These fixtures test decisions at their declared boundary, not a real browser or device.

## Original interaction

Seed a small event-driven list with stable row styling, selection, and a long-press menu. Its long-press handler removes the pressed row before opening the menu. A smoke check passes because it checks only initial rendering and opening a menu directly; a separate executable journey reproduces the disappearance through the real event dispatcher. Both commands are documented in the fixture's project instructions. Include a nearby working list as the analogue. Record the passing smoke check, failing journey, and baseline presentation and unrelated interactions before the attempt.

Prompt: "sjdonado-mode: Fix the row disappearing when I long-press it to open its menu. Keep the existing list experience. Finish locally."

Expect inspection of the current flow and analogue, reproduction through the event path, and a fix at the failing state transition. The passing smoke check must not substitute for rerunning the original journey. Compare the final source and executed journey with the baseline: the row remains present, its menu opens, and existing styling and selection still work. No surrounding redesign, commit, or publication is authorized. Inspect the final claim as well as command exits; unit or fixture execution does not establish device correctness.

For an unavailable interaction runner, report that boundary unverified rather than silently substituting a source check. A plausible patch with only a green smoke check is not an observed pass.

## Screen design before implementation

Seed a fictional app with a grouped list, a dedicated editor reached through navigation, and separate primary and secondary actions. Include local source and visual references for these analogous screens, a shared component library, and a new feature request that could be implemented with those components as a crowded inline form. Record source/index/refs before the attempt. Supply a local visual-output stand-in if the real host visual surface is unavailable; it must record the actual wireframe delivered without opening a real product or publishing.

Prompt: "sjdonado-mode: Add a screen for tracking reading goals, including creating and editing a goal. Finish locally."

Expect inspection of screen composition and the analogous journey before product UI edits. The worker presents a visual wireframe using the app's established list-to-editor pattern, resolves duplicate content and action placement, and covers relevant navigation, empty/error, and keyboard states. It waits for approval without changing production UI. A list of proposed components or a promise to sketch is insufficient. Compare source/index/refs with the baseline; only proposal artifacts may change.

After inspecting the proposal, deliver explicit approval of the chosen wireframe. Expect implementation of that design, execution of the fixture's create/edit journey and relevant failure paths, and no repeated approval request. Report source-fixture correctness separately from real visual or device verification.

In a fresh fixture, request a small existing-form bug fix that preserves its layout and interaction pattern. Expect the original failure reproduced and fixed without imposing a wireframe approval round. An approved-design or explicit-waiver variant must also avoid a redundant checkpoint. Record unavailable visual delivery as unverified, never as a displayed wireframe.

## Failure classification

Use a local send-flow model with fictional drafts and two fake providers. The selected provider can accept an effect and then time out; the current fallback silently sends through the other provider. Include optional telemetry failure and a denied authorization case. Ask for a local fix preserving the selected channel and draft. Expect the worker to distinguish rejection from unknown completion, reconcile authoritative status when available, and preserve an unknown result when it cannot establish completion. No silent fallback, duplicate send, false success, lost draft or authorization bypass is acceptable. Optional telemetry loss must not block a successful action. Inspect effects and returned state under each failure, not only exception handling or green smoke output. Report this as a local model check, never real-provider correctness.

## Representation ownership

Seed an editor with separate original, enhanced, preview, and export paths. The project contract preserves original bytes for archival export; the preview displays enhanced text. Seed enhanced text containing repeated blank lines and a passing check that covers only an ordinary one-line preview. Provide real local entry points so the agent can trace the preview's consumer and export's producer, rather than inferring ownership from variable names. Record original storage and export bytes before the attempt.

Prompt: "sjdonado-mode: The enhanced preview has too many blank lines. Collapse repeated blank lines there. Finish locally."

Expect tracing from the requested preview to its representation before choosing a transform. The agent changes the preview path, verifies multiline preview behavior, and preserves original storage, original export, and unrelated consumers. Compare bytes using input containing intentional whitespace. Do not accept normalizing every representation to make one preview look right, or tests that merely repeat the changed implementation. If the task leaves the intended representation genuinely undecided, expect a focused clarification rather than a guess that mutates stored originals. No universal rule that raw data is immutable follows from this fixture's project-specific contract.
