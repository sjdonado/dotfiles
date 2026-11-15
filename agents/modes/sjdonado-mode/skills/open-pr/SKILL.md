---
name: open-pr
description: Publish an authorized task branch and open or refresh its PR, completing the requested opened-PR or green-PR outcome.
---

Use existing publication authority for this scope. Mode activation alone grants none. A direct PR request covers necessary commits, push, creation or refresh; it does not authorize review replies or merging. Resolve explicitly undecided behavior before publication. Do not add a separate acceptance document or review ceremony.

1. Inspect the task branch, full index, and complete intended diff. Reuse the existing checkout; read worktree when isolation is needed. Never commit to the default branch. Preserve unrelated work. If unrelated files are staged, use `git commit --only -- <intended-paths>` and leave the other index entries intact; if ownership overlaps, resolve it before committing.
2. Complete the delivery stage of principle-prove-it-works over the accumulated change, including deferred checks. Reuse valid evidence. Stop before committing, pushing, or opening while a relevant required local check is failed or unavailable. Fix in-scope failures; honor a no-edit instruction. Report the exact blocker without publishing. Optional unavailable evidence stays explicitly unverified and cannot support a readiness claim that needs it.
3. Read the repository's PR template and standards. Prepare the title and body before creation. Explain the problem, resulting behavior, actual verification, meaningful risks, and unverified behavior. Include media only when it explains or verifies the change; prose and configuration changes need none. With gh, pass multiline text through `--body-file` or stdin, never interpolated shell text or literal backslash-n separators.
4. Stage explicit intended paths, commit per principle-write-for-the-reader, and push the authorized branch. Create a normal PR, or a draft when requested. Refresh an existing PR in place, preserving human context, issue links, and checked items. Never create a second PR for the same task. Link the URL through the host tool when available, then read back the body to check formatting and evidence.
5. Match the requested stopping condition. For opened PR, report its URL and current check state without starting unsolicited monitoring. For green PR or explicit monitoring, complete required remote checks and check mergeability, using the host's event-driven watcher when available. Fix in-scope failures, rerun evidenced flakes once, and resolve mechanical conflicts. Ask only for semantic conflicts or rewriting shared history outside existing authority. Pending checks are not a green result.
6. Report the requested outcome or concrete blocker and anything unverified. Update useful existing task state. Never merge.

If the host owns PR creation or no forge capability is available, hand back the checked title, body, and required metadata and state that creation is unverified. Do not claim a PR exists from prepared text.
