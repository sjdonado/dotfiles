---
name: feature-map
description: Build, extend, or refresh a mobile or web UI feature map with real simulator or browser screenshots and a shared component dependency graph. A refresh revisits every screen and state in the map.
---

# Feature map

Use [the inventory and evidence contract](references/contract.md) and the bundled renderer. Every project uses the same outputs, `feature-map.html` and `feature-map.json`, plus the source inventory, evidence manifest and raw screenshots required to regenerate them. Reuse an existing feature map directory when continuing an audit.

## Local execution

A feature-map request authorizes routine, reversible local audit steps. Proceed without asking for confirmation to inspect source, start the normal local app and disposable test services, use existing synthetic fixtures, walk the app with supported tools, capture screenshots, and regenerate the audit artifacts in the current workspace.

Use the project's normal entry points and fixture workflow. Keep capture artifacts under the audit directory and use direct tool calls for navigation, capture, and generation. Do not inject temporary routes, entry points, or fixture code into the product tree to stand in for a failed backend or normal app flow. Diagnose the startup failure and continue any independent walkthrough work. If the supported flow remains unavailable, record the affected states as blocked.

Honor approvals required by the host. If a necessary step triggers one, name the specific pending action and continue independent work. Do not retry through another command or tool to avoid the gate.

## Refresh an existing feature map

“Refresh the feature map” means a full walkthrough of the current app for the map's existing platforms and coverage. Before capturing, reconcile the previous map and evidence manifest with the current source inventory. Use every still-applicable screen and captured state as the checklist, add newly reachable screens and states, and record routes or states removed from the app. Keep distinct entry points and mapped role, device, and viewport variants in scope.

Open every checklist entry in the running app with supported device or browser tooling. Repeat its navigation and interactions, confirm the resulting state, and take a fresh screenshot even if it looks unchanged. Do not reuse old images, fill gaps from source or mocks, or sample only changed screens. Keep previous captures only as separately labeled history.

Update the source inventory and evidence manifest to match this walkthrough, including screenshot paths, route and destination references, state titles, findings, and component and shell references. Regenerate both artifacts from the fresh evidence. Reconcile the rendered gallery and companion JSON against the checklist before calling the refresh complete. If a screen or state remains blocked, list it and its blocker, label the refresh incomplete, and keep its prior screenshot out of current coverage.

## Walkthrough and generation

1. Inventory the app's real route tree and shared shells from source before walking the UI. Preserve deep links, redirects, and distinct entry points that reuse an implementation. Trace component imports and barrel exports to their implementations, record conditional renders and actions, and classify components by ownership. Prefer the project's router manifest or parser when available. Normalize its results to the contract. Routes and source locations alone establish possible states.
2. Walk the actual app with its supported simulator, device or browser tooling. Open each entry point and exercise every reachable action that renders a distinct state, including overlays, permissions, keyboard, validation, loading, offline, empty, error, success, dismiss and return behavior. Use synthetic fixtures for states that depend on data, role or entitlement. Capture only after the expected screen or state is visible. For an explicitly scoped extension or comparison, retain earlier evidence and label its phase accurately.
3. For each visited state, inspect layout stability, clipping, spacing and whether it reuses the established UI library and platform-native controls. Record what you observed, the route and fixture, and any authorized fix. After a fix, recapture the states affected by that fix using the changed app. Keep source-only candidates and blocked states visible in the JSON inventory and name what remains unverified when reporting coverage.
4. Generate both artifacts with `python3 scripts/build.py --inventory <inventory.json> --output <audit-directory>`, using the script path relative to this skill. Open the gallery and verify that the screenshots appear in feature order, in one self-contained page, with captions and no filters, search or expandables. Check representative component blast radii in the companion JSON, including shell consumers. Link both outputs in the handoff.
