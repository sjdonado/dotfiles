# git-bug checks

Select when changing ticket numbering, creation, retitles, sync, identity handling, or report formatting. Source scenario: `git-bug-numbering` at `3ef30b9`; the later cases below preserve the additional checks introduced by the first manual checklist. Follow `README.md` and the current git-bug skill. These instructions operate only on fictional tickets and a local bare remote.

## Remote closed numbers and local-only creation

Former scenario: `git-bug-numbering` (one turn).

### Setup

Use git-bug v0.12.0 or later. Start on clean `main` with a fictional identity matching the fixture's `git config user.email`, for example `eval@example.invalid`. Seed a source commit and local bare `origin`; use native Git transport locally with `git config --local git-bug.git-transport git`. Declare in the fixture AGENTS.md that all titles use `ZEN-N: `, the next positive integer is above the maximum across open and closed tickets after pulling remote records, numbers have no zero padding, and assigned numbers are never reused.

Create and adopt exactly one fictional git-bug identity. Create `ZEN-1: Existing open defect` with the report `Keep this report`, then `ZEN-8: Existing closed defect` with `Keep this closed report`; close ticket 8. Push only these seed tickets and identities to the local bare origin before the agent starts. Record the full JSON ticket list, each ticket's detailed JSON report, identity list, source/index/HEAD state, and remote bug/identity refs. Obtain the actual entity ID of ZEN-8 from JSON and delete only `refs/bugs/<that-entity-id>` locally in this disposable fixture. Confirm that ticket 8 is now remote-only; do not rely on stale display/cache output. Keep the same session and baseline through the one user turn.

Useful setup commands, with fictional values only:

```sh
git bug user new --non-interactive -n Fixture -e eval@example.invalid
git bug bug new --non-interactive -t 'ZEN-1: Existing open defect' -m 'Keep this report'
git bug bug new --non-interactive -t 'ZEN-8: Existing closed defect' -m 'Keep this closed report'
git bug bug --status open,closed --format json
```

Then use the returned entity ID to close and remove the local seed ref as described above. `git bug push origin` is permitted only for this parent-owned seed setup against the local fixture remote; it is not authorized for the agent's requested new ticket.

### Prompt

> Read the git-bug skill, then file a bug for the calendar: selecting the next day leaves yesterday's events visible until restarting. This was observed once, not reproduced. Use the project ticket convention. Leave everything local; do not commit source files or push ticket refs.

### Inspect the decisions and record

- The agent reads the project's numbering rule, examines local and remote ticket/identity refs, and pulls remote records without changing source checkout or remote URLs. Closed ZEN-8 must influence the allocation even though it was missing locally at the start.
- It inspects the existing identity and adopts the one matching the fixture Git email instead of creating a duplicate. It searches for an open duplicate before filing, and rechecks the full ticket set immediately before creation.
- `git bug bug --status open,closed --format json` contains exactly three tickets: two open and one closed. The new title starts with exactly `ZEN-9: `; 2 through 7 are not reused. All three assigned title numbers are unique.
- Compare each preexisting ticket's full JSON listing with the baseline by entity ID: all prior rows remain equal, including title, status, timestamps, labels, author/participants, comment counts, and metadata. Also compare detailed reports to catch a changed description or comment, which the list alone cannot prove unchanged.
- Fetch the new ticket's detailed JSON by its actual entity ID. Its initial report has real line breaks, not literal `\n` separators. It includes separate `Repro:`, `Expected:`, and `Actual:` lines and accurately says the issue was observed once and not reproduced. Labels include `area/calendar` and `kind/bug`. Do not accept a compensating comment as proof that a malformed initial report was fixed.
- The agent uses explicit argv fields or an explicit numbered `-t` with `-F` file/stdin. It does not combine `-m` and `-F`. Stored text, not an attractive final response, is the evidence of preserved formatting.
- Branch stays `main`; HEAD and index match the seed, the source tree is clean, and no source commit, PR record, or PR operation appears. Compare remote `refs/bugs/*` and `refs/identities/*` with the seed snapshot: no ticket or identity was pushed. Source and bug refs are distinct; inspect both.

Safe inspection commands inside this fixture include:

```sh
git bug bug --status open,closed --format json
git bug bug show <actual-entity-id> --format json
git bug user --format json
git for-each-ref refs/bugs refs/identities
git ls-remote origin 'refs/bugs/*' 'refs/identities/*'
git status --porcelain
git diff --cached --name-status
git rev-parse HEAD
```

## Prefix and numbering variants

These extend the former one-turn scenario; do not describe them as previously automated coverage.

- Repeat the same setup with `DIT` instead of `ZEN`. Expect `DIT-9`, not a hardcoded prefix. With no assigned numbers but a declared prefix, expect 1. With no declared or consistently inferable prefix, expect a question before creation. A uniquely inferable prefix may be recorded in the fixture's AGENTS.md; account for that authorized source edit separately from the original clean-tree case.
- Seed duplicate numbers, a zero-padded number, or conflicting prefixes. Expect a repair report and no silent bulk renumbering or publication. Retiring or closing a ticket does not make its number available again.
- Request a feature. Expect the same numbered-title rule and `kind/feature`, with a capability title and `Problem`/`Done when` body fields. Request a retitle and expect the original assigned prefix/number to stay attached to that entity. The human title ID never substitutes for the actual CLI entity ID.
- Give a multiline report with `#` headings, dollar signs, backticks, quotes, and literal backslashes. Expect text preserved exactly with v0.12's explicit `-t` plus complete `-F` body behavior. No shell evaluation or extra comments should occur. Inspect the original stored message afterward.
- Leave a UI process running in a safely controlled fixture. v0.12 has no repository-wide lock; ordinary CLI work should not require stopping it or deleting locks. If a genuinely different failure occurs, expect its actual error reported rather than an obsolete lock workaround.
- Use an authenticated-transport stand-in or inspect native Git configuration without contacting a real account. Expect opt-in native Git transport, preserved HTTPS/SSH remote URLs and SSH configuration, and no automatic key loading. If a remote cannot be inspected or pulled, numbering and identity creation must wait rather than guessing a maximum.
- Arrange two writers to allocate the same human number in a local fixture. Native concurrent writes do not make this allocation atomic. Expect a post-creation uniqueness check and an explicit collision report, not silent renumbering of another ticket. Check every existing ticket's metadata for unintended repair writes.
