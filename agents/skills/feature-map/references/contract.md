# Feature map input and output

Use project-relative source paths with forward slashes. Keep route IDs stable across captures, including distinct navigation entries for a shared screen. Keep the feature names and the order of screenshot entries intentional. The renderer takes the feature order from the first capture in each feature and preserves capture order within it.

## Source inventory

Write UTF-8 JSON with these fields.

| Field | Required contents |
| --- | --- |
| `target` | Short observation target, for example `iOS simulator`, `Android emulator` or `web browser` |
| `baseline` | Source revision inspected. Use an explicit identifier if it has no Git revision |
| `routes` | Array of `{id, file, href, layout, shell, feature}`. `layout` is a boolean and `shell` is an outer-to-inner array of source files. Use optional `alias` for the implementation of a re-exported route |
| `nodes` | Object keyed by source file. Each node has `platform` (`shared` or a real platform), `kind` (`route`, `library` or `feature`), `edges`, `jsx`, `native`, `external` and `surfaces` |
| `existingCases` | Optional project case index. Entries use `{id, title, line, source}` |
| `auditedModules` | Optional array of existing node paths inspected or changed |
| `presentation` | Optional `title`, `heading`, `phaseLabels` lookup, and `defaultPhaseLabel`. Use these for report identity and historical captions |

An edge is `{target, symbol, line}`. Resolve local wrappers, aliases, platform-specific files and re-exports for the target being audited. Map UI edges only. For a non-JSX framework, put rendered component or template tag names in `jsx`. Keep built-in native controls in `native` and external component-to-package mappings in `external`.

A surface has `{id, line, kind, expression}`, with an optional `branches` object for conditional alternatives. Distinguish interaction, overlay, feedback, variant, navigation and effect. Use a stable source location for reproduction. An optional `verification` object may record a blocked, unverified or unreachable candidate with its reason. Use empty arrays or objects where nothing applies. Route entries for code-defined navigators, server routers or native view controllers follow the same schema as file-based routes.

The renderer derives `dependencies`, `shellDependencies` and `library` on routes, and `directConsumers`, `affectedRoutes` and `affectedThroughShell` on nodes. Use these fields for shared-component impact reviews. Where the code changes dynamically at runtime, record the observed alternatives and describe any gaps in the source inventory.

## Screenshot evidence

Place `evidence.json` and a `screens/` directory in the output directory. Each observed case is a JSON object with `id`, `route`, `state`, `review`, `image`, `fixture` and `phase`.

- `id` is a unique, lowercase case ID with digits and hyphens allowed. The raw image path is always `screens/<id>.png`.
- `route` is the inventory route ID. For a redirect, also include the observed destination in `destination`.
- `state` is the screenshot title and alt text. `review` describes the visible outcome and reuse or layout finding.
- `fixture` names the synthetic setup. `phase` can label initial, before-fix, candidate or historical evidence. Fill in the phase consistently when comparing runs.

Use the full viewport when possible. The renderer preserves image aspect ratio, including landscape web captures. Keep screenshots free of secrets and personal data. Capture route and interaction evidence only after confirming the visible state, and keep assertions or replay steps when the project already supports them.

The canonical HTML groups every embedded PNG by feature and follows each with its review and route context. The companion JSON includes the complete inventory and evidence manifest. A counted observation always has a screenshot. A generated route or dependency establishes source coverage.
