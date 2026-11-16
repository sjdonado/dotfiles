---
name: principle-preserve-product-experience
description: Preserve existing product journeys when adding or fixing user-facing behavior. Read before changing UI flows, interactions, or presentation.
---

Before changing a user-facing flow, inspect its current journey and the closest existing screens serving the same purpose. Identify their screen composition, navigation, action hierarchy, form placement, typography, spacing, and feedback. Use the actual product when available; distinguish source-derived assumptions from observed behavior. Reusing individual components does not establish that the screen follows the product's patterns.

Treat the requested capability as the scope of change. Reuse established components and screen patterns; preserve layout, navigation, selection, gestures, and styling outside that scope. A new interaction does not authorize replacing the surrounding experience. An explicit redesign may deliberately change the baseline within its agreed scope.

For a new screen or a substantial change to screen composition, navigation, or an interaction flow, present a low-fidelity visual wireframe before implementing the product UI. Show how it follows the inspected analogues and identify any deliberate departures. Include the entry, list/detail/form transitions, action hierarchy, and relevant empty, loading, error, and keyboard states. Avoid duplicated content and competing actions by resolving their placement in the proposed journey. Show the actual wireframe through the host's supported visual surface; a promise to sketch or a prose description alone is not the checkpoint.

Wait for the user's approval of that design before implementing it in the product. Continue independent settled work while waiting. An already approved design or explicit instruction to skip design approval satisfies this checkpoint; do not request approval again. Small fixes, copy changes, and additions that preserve the established screen and interaction pattern can proceed directly. A requested wireframe or exploratory visual prototype can be built for review within its agreed scope; permission to explore does not itself approve the production design. If the product cannot be inspected, label the wireframe's source-derived baseline and unresolved visual assumptions rather than claiming a visual match.

Follow the affected journey through its relevant states and failure paths, including retained interactions that share the changed component. Apply principle-prove-it-works for the current verification stage and completion claim. A polished isolated component does not establish that the journey still works.
