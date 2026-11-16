# Publication evidence gate

Recover the required behaviors from the user request and accepted scope in existing task state. Preserve those requirements across prototype, feedback and publication turns. If the user explicitly selects a narrower slice, record that decision and keep the undelivered original scope visible. An agent-authored limitation or a request to open a PR is not that decision.

Before committing, pushing, creating a PR or handing ready-to-publish content to a host, serialize the existing verification record into temporary JSON outside tracked source. This is gate input, not a new specification or acceptance document. Use stable IDs from the recorded requirements; every required behavior needs one decisive row identifying its real entry point, scenario, expected result, observed result and executed evidence. A regression suite can be cited only when its identified case actually traverses that behavior's required boundary. Unit checks remain static for a promised application journey; an executable demonstration of an explicitly scoped public library API can be runtime evidence at that API boundary.

Use a source identity derived independently from the exact tested snapshot. For clean committed source, use the commit SHA. For pending changes, use the tree or content identity of the intended tested files, with intended changes staged and unchanged since testing. A stale HEAD SHA alone does not identify uncommitted changes. Exclude unrelated work from the intended snapshot and preserve its index entries. Refresh affected evidence if source changes; do not simply rewrite the identity of stale results.

The JSON shape is:

```json
{
  "change_type": "functional",
  "source_revision": "tested-source-identity",
  "body": {"template": "fallback"},
  "tickets": [],
  "requirements": [
    {"id": "save-and-reopen", "behavior": "The requested entry point saves a value and shows it after reopening."}
  ],
  "checks": [
    {
      "requirement_id": "save-and-reopen",
      "status": "executed",
      "kind": "runtime",
      "entry_point": "The actual application route or public command",
      "scenario": "Enter a fictional value, save, reopen and read it",
      "expected": "The same value appears after reopening",
      "observed": "The value matched; the scenario assertion passed",
      "command": "The actual command or reproducible interaction sequence",
      "artifact": "/tmp/task-evidence/journey.log",
      "source_revision": "tested-source-identity"
    }
  ],
  "demo": {
    "status": "command",
    "reason": "This scoped contract has a nonvisual command interface",
    "command": "The actual reproducible demonstration command",
    "artifact": "/tmp/task-evidence/journey.log",
    "source_revision": "tested-source-identity"
  }
}
```

Replace the illustrative values with observed evidence. Artifacts must be nonempty local files; never provide environment-secret files or private payloads. The checker inspects file metadata, not artifact contents, and never executes a recorded command or uploads a file. Inspect the actual outputs yourself and ensure the PR's references can be accessed by its reviewer or receiving host.

Run `python3 <resolved-open-pr-directory>/scripts/check_delivery.py --source-revision <independently-derived-identity> --branch <actual-task-branch> --body-file <prepared-pr-body.md> < <temporary-evidence.json>`. Derive the actual branch from Git rather than copying it from the evidence record. Include associated tickets as described in the shared policy's `task-linkage.md`, primary first, or `"tickets": []` when none is available. The shared checker validates the primary ticket token in the branch and each actual Resolves/Refs line; record a permitted branch exception instead of renaming an existing published branch.

Every change declares `body.template`. Use `fallback` only when no project structure is defined: the actual body must contain nonempty Summary, Reviewer notes, Verification, and Demo sections, once each, in that order. Verification includes an Executed or Static label and the actual check, environment and result. Instructional comments, fenced example headings and placeholder-only content cannot satisfy a required section. A copied, unfilled template must fail.

For a project-defined structure, declare the actual template or standards file, its required heading order, and the headings that carry summary and verification:

```json
"body": {
  "template": "repository",
  "template_path": "/path/to/project/.github/pull_request_template.md",
  "required_headings": ["Overview", "Testing", "Demonstration"],
  "summary_heading": "Overview",
  "verification_heading": "Testing"
}
```

This fragment belongs inside the evidence object. Use the repository's actual required sections, excluding sections it explicitly makes optional; preserve its heading order. Its standards file can define the structure when no template exists. `template_path` must be an existing nonempty nonsecret local file; the checker inspects metadata only, so the lead must read the file and confirm the mapping is faithful. A functional custom structure includes the demo heading in `required_headings`, with `demo.heading` set to that equivalent name. Required heading titles must be distinct. A project structure may omit Reviewer notes or a nonfunctional Demo; meaningful verification remains required. Do not select a smaller structure to conceal missing evidence.

Functional changes require nonempty requirements, exactly one executed runtime row per requirement, matching source identities and a demo disposition. Demo status `capture` requires an inspected artifact (`"inspected": true`); `command` requires its reproducible command and output artifact. `blocked` and `not_applicable` cannot pass for a functional change. Respect capture restrictions by choosing an appropriate nonvisual demonstration, not by omitting the required behavior.

Prose or configuration edits that change no functional behavior use `"change_type": "nonfunctional"`, empty requirements/checks, and a `demo` with `"status": "not_applicable"`, the source identity and a concrete reason. Classify from the requested change, not from the subset implemented; do not relabel unfinished functional work as documentation to bypass the gate.

A passing checker establishes the declared body structure, required section order/content, a labelled verification section, complete declared behavior coverage, valid dispositions, matching supplied identities, and artifact presence. It cannot establish that the correct project template was selected, requirements were captured honestly, a command ran, an artifact proves its claim, or the chosen entry point is the right one. The lead still compares the record with the original request and inspects evidence. Where the repository provides an enforced PR validator, apply it too. A failure blocks publication; changing a label, inventing evidence or omitting a requirement is not a repair.
