# Keep reasoning in ADRs instead of a specification lifecycle

The OpenSpec tree mixed proposals, designs, delta specifications, task lists, historical findings, and unarchived changes. Several artifacts described superseded routing or provisioning choices while their checklists still contained pending validation. Agents needed the reasoning behind the setup, but traversing that lifecycle created boilerplate and made historical intent look like a current contract.

Use `adrs/` for the durable reasoning behind major setup changes. A record explains the decision and its material consequences; it is not a required proposal, implementation checklist, generated spec, or archive gate. Current commands and constraints remain in project instructions and owning implementation files. Task progress belongs in T3 or a useful local continuity note, not in an ADR disguised as a backlog.

The OpenSpec CLI, its skills, and its tracked artifacts are removed together. The replacement records preserve the useful lessons rather than port every document into a new directory. Git history retains the original proposals and findings when deeper archaeology is necessary. Existing unverified work stays unverified; converting its rationale into an ADR does not close its acceptance tasks or certify a host transition.

This gives agents a short explanation of why the setup changes without requiring another workflow invocation. The cost is that ADRs are curated summaries rather than a complete requirements ledger. When a major decision changes, a new record should identify the earlier decision it supersedes and explain the evidence that changed the choice.
