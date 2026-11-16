# PR structure fallback and verification gate

Date: 2026-11-16. Starting revision: `6c428e7`, with the local open-pr changes applied. Selected sections: publication/fallback-structure-and-verification and body-validation-and-host-handoff. No real product, forge, tracker or account configuration was changed for these evals.

## Frozen setup

Two disposable repositories contained a completed fictional integer-summing CLI, an executable two-case project check, synthetic identities, disabled signing/hooks, committed seeds, existing task branches and local bare origins. The fallback seed was `08c7e597f0ad089dc5e424cf1a834b32f90c0753`; the repository-template seed was `ed63654da42dcadcf4cc53882dadd9e60752f209`. Source hashes, full indexes, HEADs and refs were recorded before either turn. The frozen instruction-manifest SHA-256 was `36a574ef71462f879bcc3f8706960d04b800987b2bdeba292a2449824fe8bf64`.

One project had no PR structure. The other required Overview, Compatibility, Testing and Demonstration in that order. Both workers received trusted mode activation, the user request to prepare the completed CLI's host handoff, and a local stand-in command. No acceptance notes, expected output body or evaluation observations were supplied. The stand-in independently ran the frozen delivery checker against the supplied body/record before recording a simulated handoff; it could not contact a forge. Prepared files and logs remained outside tracked source.

Expected decisions: select the bundled asset only without a project structure, preserve equivalent project headings otherwise, execute the required check and real CLI scenarios, validate the actual body, and deliver only a local simulated handoff without changing source or refs.

## Observed results

- Fallback: the worker checked for repository templates, read the bundled asset and standards, ran the project check and three CLI scenarios, and prepared Summary, Reviewer notes, Verification and Demo. Optional sections and instructional comments were removed. It declared the fallback, passed the real checker and delivered the identical body through the local stand-in. No template or standards file was installed in the project.
- Repository template: the worker read the real project template and preserved all four headings, including Compatibility. It mapped Overview/Testing/Demonstration in the evidence record, executed the two-case project check and direct CLI scenarios, passed the real checker and delivered the matching body. It did not append fallback headings or invent flags, labels or tickets.

The lead inspected both bodies, records, command logs and stand-in records. Independent comparisons confirmed all source hashes, indexes, HEADs, local refs, remote main refs and clean worktrees matched their baselines. The two recorded handoff bodies exactly matched the prepared files. The lead reran both project checks and revalidated both stored bodies/records against the final checker successfully. Action/resource inventories are worker records, not complete independently audited provider tool traces.

## Mechanical checks

All 28 delivery-checker tests and 13 shared ticket/workspace tests passed. Ten direct CLI probes accepted a filled fallback, equivalent custom headings, and a project nonfunctional body without Demo; they rejected undefined structure, the actual copied unfilled asset, missing verification, label-only or comment-only verification, reordered sections, and green static-only evidence for a required runtime behavior.

The delivery suite additionally covers duplicates, example headings inside comments/fences, nested sections, required custom fields, unsafe template paths, stale or missing evidence and existing secret-path protections. Frontmatter and eval-index/reference checks are structural evidence only.

## Limits

The frozen model attempts predate a small parser correction preventing a nested required section from filling its empty parent; the regression test and final stored-body reruns cover that correction. They also predate replacing the writing principle's conflicting advice to infer structure from older PRs; the frozen open-pr entry already selected the explicit fallback. These corrections were not followed by extra model turns.

The checker validates declared mappings, body shape and artifact metadata. It does not read template contents, choose the project template, verify semantic coverage, prove commands ran, or intercept arbitrary forge tools. The lead must inspect those claims; consuming-host enforcement is not implemented. Nonfunctional custom-template, absent/invalid-body and safety variants were exercised by code/CLI checks, not additional model turns. No visual capture, upload, review reply, real PR creation, remote CI or host-session reload was exercised. Installed releases, setup, CI declarations and pinned vendor bytes remain unchanged.
