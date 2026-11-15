---
name: principle-preserve-product-experience
description: Preserve existing product journeys when adding or fixing user-facing behavior. Read before changing UI flows, interactions, or presentation.
---

Before changing a user-facing flow, inspect its current journey and the closest existing analogue. Identify the entry point, affected interactions, feedback, and visual conventions. Use the actual product when available; distinguish source-derived assumptions from observed behavior.

Treat the requested capability as the scope of change. Reuse established components and patterns; preserve layout, navigation, selection, gestures, and styling outside that scope. A new interaction does not authorize replacing the surrounding experience. Resolve a consequential product fork before implementing it; an explicit redesign or exploratory prototype may deliberately change the baseline within its agreed scope.

Follow the affected journey through its relevant states and failure paths, including retained interactions that share the changed component. Apply principle-prove-it-works for the current verification stage and completion claim. A polished isolated component does not establish that the journey still works.
