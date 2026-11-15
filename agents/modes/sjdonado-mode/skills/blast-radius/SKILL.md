---
name: blast-radius
description: Trace what a shared behavior, interface, or dependency change could break beyond the diff and test the assumptions that make it safe.
---

Use for shared behavior, interface or dependency changes, or a request to assess what a diff could break. Work within the task's authority; finding a risk does not authorize unrelated repairs.

1. Trace the changed contract through its producers and consumers. Include serialized values, persisted data, other languages, lifecycle ordering, configuration and downstream dependencies where relevant. A symbol search is a starting point, not a complete consumer inventory.
2. Inspect the version and implementation actually used, including local patches, before relying on a library's behavior. Identify the one or two assumptions that most consequential risks depend on.
3. Try to falsify those assumptions with the cheapest discriminating executable check against real code. Exercise an affected consumer or failure path, not a test that merely repeats the proposed implementation. Follow principle-prove-it-works for the current stage; a prototype can defer delivery evidence but must name the gap.
4. Separate confirmed risks, checked-and-cleared cases, and unverified assumptions. Each retained risk names the failure mechanism, affected consumer, source location and evidence or missing check. Do not invent callers or turn an untested possibility into an observed defect.
5. Report the safety assumption and its proof or limit alongside the relevant verification. Include consequential unresolved risks in the PR body when publishing. A clean list of search results is not proof of compatibility.
