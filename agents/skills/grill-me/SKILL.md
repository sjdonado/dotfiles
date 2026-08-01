---
name: grill-me
description: A relentless interview that attacks the load-bearing assumptions in a plan or design before they become expensive. Two modes, interactive for a human-driven grilling and self-grill for resolving your own open questions with evidence first. Use when a plan needs pressure, when scope feels underspecified, or before committing to an approach.
---

# Grill Me

Cheap to change a plan. Expensive to change a merged diff. This closes that gap by attacking the plan while it is still words.

Grilling is not a checklist and not a summary. It is an attempt to break the thing.

## Find the load-bearing assumption first

Before asking anything, identify what the plan **depends on** being true. Attack that. Do not attack the surface.

A load-bearing assumption is one where being wrong changes the approach, the scope, or whether the work happens at all. Everything else is detail, and interrogating detail while the foundation is unexamined is theatre.

Rank by consequence, then start with the worst one.

## Mode: interactive

Human-driven. The default when invoked directly.

- **One question at a time.** Wait for the answer. A batch invites skimming, and skimming is what you are trying to prevent.
- **Hardest first.** If the plan dies on question one, every later question was wasted.
- **Follow the crack.** When an answer is vague, hedged, or shifts the subject, push there instead of moving on. "It depends" means you found something.
- **Use the repository, not just logic.** "Does anything here already do this?" beats an abstract objection. Search before asserting.
- **Never accept a plan restatement as an answer.** Saying it again louder is not evidence.

Stop when the design either survives, in which case say so and name what would still break it, or breaks, in which case say what broke and what the smaller version looks like.

## Mode: self-grill

No human in the loop. Use this when a workflow needs its own approach pressure-tested and serial human grilling would be the bottleneck.

1. **List the assumptions** the approach depends on, ranked by consequence.
2. **Resolve what you can**, in this order: search the repository for precedent; check history for whether this was tried before; load and follow the `evidence` skill for any claim about runtime behavior, impact, or frequency. Most open questions die here, because they were answerable and nobody looked.
3. **Kill the plan if it deserves it.** If evidence refutes the premise, say so and stop. That is a success, not a failure.
4. **Present only survivors**, in one batch, each carrying the decision, what you already checked and what it ruled out, the options with consequences, your default, and the cost if the default is wrong. Per the escalation contract in `AGENTS.md`, if three or fewer read-only actions would settle a question, take them instead of asking it.

A self-grill that produces a long question list did not do step 2.

## What makes a good question

- Falsifiable: answerable with evidence, not opinion.
- Consequential: a different answer changes what gets built.
- Specific: names the file, endpoint, state, or number in question.
- Not already answered: check the conversation before asking again.

## What is not grilling

Restating the plan back as a question. Asking for confirmation. Listing risks without ranking them. Interrogating edge cases while the core mechanism is unverified. Producing one question per section because there are sections.
