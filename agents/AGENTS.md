# Global agent conventions

## Planning

Use the harness's native plan mode for non-trivial changes. Before proposing an implementation, trace the relevant system end to end, identify the source of truth and lifecycle implications, clarify only load-bearing ambiguity, and recommend the smallest coherent change with specific files and verification steps. Wait for approval before implementing.

## Code reviews

Use `caveman-review` for agent-initiated reviews and review loops. Use `code-review` only when the human explicitly asks for a code or pull-request review; never invoke it from another workflow or loop.

## Commit messages

When writing any git commit message, follow the `caveman-commit` skill: Conventional Commits format, terse and exact, imperative subject <=50 chars, body only when the "why" is non-obvious. No AI attribution, no filler, no emoji.

## Writing

Never use em-dashes (—) in any prose, commit message, PR text, code comment, or other written output. Rewrite the sentence, or use a comma, colon, parentheses, or a period instead.

## Links

When rendering a link, always show the complete absolute URL as the visible text, including the scheme and host (for example, `https://example.com/path`). Never hide a URL behind Markdown alias text such as `[test](https://example.com/path)`. Never render relative URLs or bare paths as links.
