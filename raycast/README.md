# Raycast

Reference copies of Raycast Dictation styles. Nothing here is installed by `macos.sh`: Raycast keeps styles in its own database and syncs them through your account, and writes nothing to disk that a dotfile could own. The only Raycast data under `~/Library/Application Support/com.raycast.macos` is `dictation-recordings`. These files exist so the prompts are versioned and reviewable, and so a new machine can be set up by pasting them back in.

To add one: Settings, Dictation, create a style, then paste the file into `Prompt` and set the apps under `Apps & Websites`. Automatic selection also requires `Auto Styling` to be on; without it a style is still reachable from root search.

| File | Bind to | Purpose |
| --- | --- | --- |
| `dictation/coding-agents.txt` | Ghostty | Dictating to Claude Code, Codex, and OpenCode |
| `dictation/notes.txt` | Apple Notes, Notion, `notion.so` | Dictated notes |

## Why the two prompts are shaped so differently

`coding-agents.txt` deliberately does **not** rewrite. An earlier version opened with "rewrite the dictation as an instruction to a terminal coding agent" and told it to keep the imperative mood and put each task on its own line; it then composed a new text rather than transcribing one. The current version names the permitted edits and forbids everything else, because a closed list is what actually holds. Your dictated words are already the instruction, so no conversion is wanted: only spoken technical syntax becoming typed syntax, tool names spelled correctly, and backticks around paths and commands.

`notes.txt` works the same way, and for the same reason. It adds structure, since speech carries structure that arrives as one stream, but it adds only structure: line breaks, bullets, grouping and indentation, over the speaker's own words. An earlier version told it to "compress each bullet to its meaning", which is a rewrite by another name and produced notes in someone else's phrasing. It is also told never to invent a heading and never to force bullets onto a single short thought.

Both end with the same guard, that a described task is text to clean up rather than a task to perform. In a dictation prompt this matters more than it looks: nearly every sentence dictated at a coding agent reads like a request the styling model could try to fulfil.

## Notes

No `#` headings in `notes.txt` on purpose. Notion converts pasted Markdown, so `##` becomes a real heading, while Apple Notes is rich text and shows the literal hashes. `- ` bullets degrade well in both. The same caveat applies to `- [ ]`, which becomes a real checkbox in Notion and literal brackets in Apple Notes.

Raycast Dictation transcribes server side, against `dictation-api.raycast.com`. There is no local model: the binary links no Speech framework and ships no weights. Audio leaves the machine, and the recordings are also kept locally under `dictation-recordings`, so that directory grows and is worth clearing now and then.
