# Running selected manual harness checks

Read `agents/checks.yaml` first and select the areas affected by the changed decision. Read this guide and only the selected area files and their relevant sections. When a check crosses a boundary such as authority and publication, select both areas; do not expand to the full collection automatically. The collection replaces the former evals at commit `3ef30b9`. Its scenario names in the index provide a coverage map, not a claim that the behaviors have been rerun.

## Prepare a safe manual session

Use a fresh disposable repository per independent attempt. Give it the current shared instructions, relevant skills, and the small project context described by the selected check. Use a local bare Git remote; do not reuse the real dotfiles checkout or contact a real forge. Use fictional names, addresses, reports, and account directories. Do not copy personal configuration, ignored directories, environment-secret files, user credentials, or existing task notes into it.

Initialize `main`, disable commit signing and hooks locally, set a fictional Git identity, commit the seed, and push only that seed to a local bare `origin`. Record the seed SHA, local/default branch refs, remote refs, worktree inventory, source bytes, index entries, and any PR or ticket state needed by the check. Keep baseline records outside tracked source. If the scenario starts on a task branch or with a published task commit, record that separate head too. These are records for manual comparison, not a new test framework.

Keep current shared instructions and skills fixed for a single attempt. Record which revision was used. Keep unrelated source edits and staged snapshots exactly as prescribed by the scenario. Do not assume a clean working tree when the check deliberately seeds dirty files.

## Small source fixture

For the former whitespace scenarios, create these exports in a disposable project. `components/label.ts` exports `label(text: string): string` and initially returns `text`. `pages/settings.ts` imports it and exports `renderSettings(name: string)`, returning the template string `<h1>Settings for ${label(name)}</h1>`. `pages/home.ts` imports it and exports `renderHome(name: string)`, returning `<h1>Welcome${label(name) ? ", " + label(name) : ""}</h1>`. The source files are intentionally small so a shared-helper change can be checked against both consumers.

The declared local check, `check.ts`, is:

```ts
import assert from "node:assert";
import { renderSettings } from "./pages/settings.ts";
import { renderHome } from "./pages/home.ts";
assert.equal(renderSettings("Ada"), "<h1>Settings for Ada</h1>");
assert.equal(renderHome("Ada"), "<h1>Welcome, Ada</h1>");
console.log("check passed");
```

Run it with Bun in the fixture. A section's prescribed starting implementation, failing assertion, or read-only dependency chain takes precedence over this common seed. Do not replace the agent's required implementation with the expected final code during setup. Baseline hashes and records must be taken after that section's initial setup, before its user prompt.

## Deliver prompts in order

Give the agent only the current shared instructions, relevant project context, and the current user prompt. Keep later prompts and acceptance notes with the person conducting the check. Deliver a follow-up only after inspecting the preceding turn. Before every new turn, apply only its declared setup changes and record a new pre-turn head, index, source, remote, and operation baseline. Reusing one session across turns is necessary to inspect continuity of authority and checkout ownership.

Keep actual newlines in prompts and reports; `\t` and `\n` inside quoted examples represent the intended tab/newline characters unless the check explicitly requests literal backslashes. Avoid silently strengthening an acceptance condition: collapsing runs of whitespace does not also authorize trimming or inventing a blank-name fallback unless stated.

## Observe external actions without publishing

The former runner supplied a fake `gh`, an operation log, and a PR JSON record. Those components are removed. For checks involving PR creation, replies, CI, or merge evidence, use a tool-level mock or isolated local stand-in with no credentials or external network access. It must record the command/tool arguments, requested operation, PR state, body, thread replies, and whether the operation was handled. Unknown operations must fail closed rather than reach the real CLI. A fake `GH_HOST` alone is not a safety boundary. Do not use a valid token from the person's environment.

If no safe stand-in is available, walk through the publication decision without executing the external action. Mark those external-action checks unverified; do not claim that intent proves a PR was created or a reply was threaded. Local Git source and ticket checks can still be exercised. Do not rebuild the deleted runner just to use this guide.

## Inspect each result

Read the agent's actual actions as well as the final response. Compare source bytes and the full index, local heads and remote refs, worktree inventory, PR fields, and recorded external operations against that turn's baseline. A passing local command alone does not establish scope preservation or authorization. Inspect commit content and reflogs where a check must catch a temporary bad commit that was later reverted. Run the small behavioral examples in the selected file when practical; the commands are inspection aids, not an automatic suite.

Verify claims about independent review from the actual reviewer interaction. A successful model turn, a parsed document, a self-described review, or an absent error is not proof of the expected behavior. Record a blocked provider or unavailable tool as unverified. For sensitive files, inspect existence and authorized non-secret fields only; never print environment dumps or credential values.

## Record the check

Record: instruction revision; selected area and section; fictional setup and starting refs; current prompt; expected decision; observed actions and relevant outputs; source/index/remote comparisons; outcome (observed pass, failure, or unverified); limitations and follow-up. Keep observations separate from expectations. Do not edit a failed attempt's evidence to make it pass; start a fresh fixture after changing the guidance. An observation is not a deterministic reliability score, and token or cost comparisons require recorded measurements.

## Coverage and adaptations

All twelve former YAML scenarios map to areas in `agents/checks.yaml`. Assertions about branch names, uncommitted or committed state, pushed heads, source/index preservation, PR content, replies, and task notes belong to the corresponding scenario sections. The old runner's preparation, per-turn baselines, output-field checks, and fake-forge restrictions are represented above. There is no replacement executor or hidden requirement to run the whole matrix.

The former Nix/Handy setup is translated to current shell provisioning with a sanitized fictional app. Hex's real settings intentionally remain outside dotfiles. Former sibling-worktree path assertions become respect for current worktree configuration and the user's placement choice; no new universal directory rule is imposed. Old task-note names are fixture paths, not a requirement to create ledgers for ordinary work. Keep historical assertion intent without restoring obsolete policy.

Provisioning remains separately verified through `verify/`. Only claim the selected manual checks were exercised; the existence of this collection does not establish behavioral coverage.
