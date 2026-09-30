# Browser MCP parity scenarios

Each scenario is one pi prompt run against one MCP server (`chrome-devtools`, `safari`, `browser`). `<BASE>` is the fixture server's origin, substituted at run time. Prompts never name a tool, a server, or an engine, so each server is judged on whether an agent can reach the outcome with it.

A scenario passes when every oracle holds:

- `answerLine`: for the three free-text scenarios (21, 23, 29), the prompt ends with a fixed final-line instruction and the oracle checks only the last line that starts with `ANSWER:` (see Oracle notes).
- `answer`: a regex that must match the agent's final answer. Each regex carries its own flags (most are case-sensitive; a trailing `i` marks the case-insensitive ones).
- `log`: an event the fixture page or server must have recorded in the run's event log (`POST /log` from the page, or a server-side hit), matched by name and optional value.
- `toolCall`: a regex over tool names, one per server, that must match a non-error call in the agent's recorded tool calls. `result.json` records it as an oracle of kind `toolCall`. Used where the outcome is an action with no page-visible trace (closing the browser).

Every scenario also has a reference solution: a scripted, model-free sequence of `browser` MCP tool calls that must pass the same oracles. It proves the fixture and oracle are correct and that `browser` can reach the outcome in principle.

## Navigation and pages

1. `nav-title`. Fixture `/title` has `<title>Parity Fixture 7Q</title>`. Prompt: "Open <BASE>/title and tell me the exact page title." Oracle: answer `Parity Fixture 7Q`.
2. `back-forward`. `/a` links to `/b`. Prompt: "Open <BASE>/a, follow the link to page B, then go back and tell me the main heading of the page you end up on." Oracle: answer `Page A heading`; log `visit b`.
3. `reload`. `/counter` shows how many times the server has served it this run. Prompt: "Open <BASE>/counter, reload it twice, and tell me the number it shows at the end." Oracle: answer `\b3\b`; log `counter 3`.
4. `new-tab`. `/links` has a `target=_blank` link to `/docs` (title "Docs 51"). Prompt: "Open <BASE>/links, open the Docs link, which opens in a new tab, and tell me the titles of both tabs." Oracle: answer `Links 50` and `Docs 51`.
5. `tabs-close`. Prompt: "Open <BASE>/a and <BASE>/b in two separate tabs, close the tab with page A, and tell me the title of the tab that is still open." Oracle: answer `Page B`; log `visit a`, `visit b`.
6. `wait-text`. `/delayed` renders `READY-83` 2.5 s after load. Prompt: "Open <BASE>/delayed and tell me the code that appears on the page once it finishes loading." Oracle: answer `READY-83`.

## Reading content

7. `a11y-label`. `/a11y` has an icon-only button with `aria-label="Submit order 19"`. Prompt: "Open <BASE>/a11y. What is the accessible name of the icon-only button?" Oracle: answer `Submit order 19`.
8. `table-sum`. `/table` has a table of 6 rows with an Amount column summing to 1234. Prompt: "Open <BASE>/table and give me the total of the Amount column." Oracle: answer `1,?234`.
9. `iframe-text`. `/frame` embeds `/frame-inner` containing `FRAME-SECRET-5`. Prompt: "Open <BASE>/frame. What secret code is shown inside the embedded frame?" Oracle: answer `FRAME-SECRET-5`.
10. `shadow-text`. `/shadow` has a custom element whose shadow root holds `SHADOW-42`. Prompt: "Open <BASE>/shadow. What code is rendered inside the custom element?" Oracle: answer `SHADOW-42`.

## Input

11. `form-submit`. `/form` has name and email fields and a submit button that POSTs to `/submit`. Prompt: "Open <BASE>/form, fill in the name Ada Lovelace and the email ada@example.com, and submit the form." Oracle: log `submit` with `name=Ada Lovelace` and `email=ada@example.com`.
12. `form-controls`. `/controls` has a select (Red, Green, Blue), a "Subscribe" checkbox, and radio buttons Small, Medium, Large, and it POSTs on submit. Prompt: "Open <BASE>/controls, choose Green, tick Subscribe, pick Large, and submit." Oracle: log `controls` with `color=green`, `subscribe=on`, `size=large`.
13. `hover`. `/hover` shows a tooltip `TIP-77` only while `#help` is hovered. Prompt: "Open <BASE>/hover. Hover over the help icon and tell me what the tooltip says." Oracle: answer `TIP-77`; log `hovered`.
14. `drag-drop`. `/drag` has a draggable card and a drop zone; a drop logs `dropped`. Prompt: "Open <BASE>/drag and drag the card into the drop zone." Oracle: log `dropped`.
15. `key-press`. `/keys` opens a modal; pressing Escape closes it and logs `escape`. Prompt: "Open <BASE>/keys and close the modal with the keyboard, not the mouse." Oracle: log `escape`.
16. `file-upload`. `/upload` has a file input that POSTs to `/upload`. The runner writes `upload.txt` containing `UPLOAD-PAYLOAD-9` in the run's working directory and passes its absolute path as `<FILE>`. Prompt: "Open <BASE>/upload and upload the file at <FILE>." Oracle: log `upload` with `UPLOAD-PAYLOAD-9`.
17. `confirm-dialog`. A button on `/dialog` calls `confirm("Delete item 12?")` and logs `confirm true` or `confirm false`. Prompt: "Open <BASE>/dialog, click Delete, and accept the confirmation. Tell me what the confirmation asked." Oracle: log `confirm true`; answer `Delete item 12`.
18. `prompt-dialog`. A button on `/prompt` calls `prompt("Your code?")` and logs the reply. Prompt: "Open <BASE>/prompt, click Enter code, and answer the prompt with PX-31." Oracle: log `prompt PX-31`.
19. `double-click`. `/dbl` has a box that logs `dblclick` on double click only; a single click logs `click`. Prompt: "Open <BASE>/dbl and double-click the box." Oracle: log `dblclick`.
20. `infinite-scroll`. `/scroll` loads 10 items at a time as you scroll; item 47 reads `Item 47: KIWI`. Prompt: "Open <BASE>/scroll and tell me what item 47 says. Items load as you scroll." Oracle: answer `KIWI`.

## Console and network

21. `console-errors`. `/console` logs `console.error("PARITY_ERR_1")`, `console.error("PARITY_ERR_2")`, two warnings, and one info. Prompt: "Open <BASE>/console. List every console error message and tell me how many warnings there were." Prompt ends with: "End your answer with a final line exactly in the form `ANSWER: <error messages separated by commas> | <number of warnings>`." Oracle: the last `ANSWER:` line lists `PARITY_ERR_1` and `PARITY_ERR_2` (either order) and the number after `|` is `2` or `two`.
22. `uncaught-exception`. `/exception` throws from a function named `explodeHere` after load. Prompt: "Open <BASE>/exception. The page throws an uncaught error. What is the error message and which function threw it?" Oracle: answer `KABOOM-6` and `explodeHere`.
23. `failed-request`. `/requests` fetches `/api/ok`, `/api/broken` (500), and `/api/missing` (404). Prompt: "Open <BASE>/requests. Which requests failed, and with which status codes?" Prompt ends with: "End your answer with a final line exactly in the form `ANSWER: <path> <status>, <path> <status>` listing only the failed requests." Oracle: the last `ANSWER:` line contains exactly the pairs `/api/broken 500` and `/api/missing 404` (either order; backticks and `HTTP` tolerated) and no `/api/ok`, so swapped codes and extra requests fail.
24. `response-body`. `/token` fetches `/api/token`, which returns `{"token":"token-XYZ-88"}`; the page does not display it. Prompt: "Open <BASE>/token. The page fetches a token from the API but does not show it. What is the token?" Oracle: answer `token-XYZ-88`.
25. `request-header`. `/header` fetches `/api/echo` with header `x-parity: 99`. Prompt: "Open <BASE>/header. What custom x- header does the page send with its API request, and what is its value?" Oracle: answer `x-parity` and `99`.
26. `post-body`. `/save` POSTs JSON `{"draft":"DRAFT-204"}` to `/api/save` on load. Prompt: "Open <BASE>/save. What JSON body does the page send to the save endpoint?" Oracle: answer `DRAFT-204`.

## Scripts, DOM, and CSS

27. `query-count`. `/items` has 17 `.item` elements, some hidden. Prompt: "Open <BASE>/items. How many elements have the class item, including hidden ones?" Oracle: answer `\b17\b`.
28. `computed-style`. `#warn` on `/style` gets its color from a class chain; the computed color is `rgb(214, 40, 40)`. Prompt: "Open <BASE>/style. What is the computed text color of the warning element?" Oracle: answer `214,\s*40,\s*40` or `#d62828`.
29. `event-listener`. `/listeners` has three buttons that look identical; only `#go` has a click listener, attached by the external script `/assets/l.js`, which builds the target id and the logged text at runtime, so `GO-CLICKED` and `go` are not in the served HTML. The handler logs `GO-CLICKED`. Prompt: "Open <BASE>/listeners. Which of the three buttons actually has a click handler, and what does the handler do?" Prompt ends with: "End your answer with a final line exactly in the form `ANSWER: <button id> | <what the handler logs>`." Oracle: the last `ANSWER:` line is `go | GO-CLICKED`, ignoring whitespace, backticks, quotes, a leading `#` and the case of the id; the logged text is case-sensitive.
30. `css-cascade`. `/cascade` has `.card { max-width: 900px }` inside `@layer base` and `.layout .card { max-width: 400px }` unlayered. Prompt: "Open <BASE>/cascade. The card is stuck at 400px wide even though a rule sets max-width 900px. Why is that rule not winning?" Oracle: answer `layer` and `400`.
31. `local-storage`. `/storage` writes `localStorage.parity = "LS-63"` and a cookie `session=SESS-17; HttpOnly`. Prompt: "Open <BASE>/storage. What value does the page store in localStorage under the key parity, and what is the name and value of the HttpOnly cookie it sets?" Oracle: answer `LS-63` and `SESS-17`.

## Emulation

32. `viewport`. `/responsive` shows `MOBILE-LAYOUT` below 500px wide and `DESKTOP-LAYOUT` above. Prompt: "Open <BASE>/responsive at a 375 pixel wide viewport and tell me which layout code it shows." Oracle: answer `MOBILE-LAYOUT`; log `viewport 375`.
33. `dark-mode`. `/scheme` shows `DARK-ON` under `prefers-color-scheme: dark`, otherwise `LIGHT-ON`. Prompt: "Open <BASE>/scheme with the dark color scheme preferred and tell me the code it shows." Oracle: answer `DARK-ON`; log `scheme dark`.
34. `offline`. `/offline` shows `OFFLINE-BANNER` when `navigator.onLine` becomes false or a fetch fails. Prompt: "Open <BASE>/offline, then simulate losing the network connection, and tell me what the page shows." Oracle: answer `OFFLINE-BANNER`.
35. `geolocation`. `/geo` asks for geolocation and prints the coordinates. Prompt: "Open <BASE>/geo with the location set to latitude 40.7128, longitude -74.006, and tell me what the page prints." Oracle: answer `40\.71`; log `geo` matching `40.7128`, which the page sends only when it receives a position, so echoing the prompt is not enough.
36. `user-agent`. `/ua` shows `UA-PARITY-OK` only when the user agent contains `ParityBot/1.0`. Prompt: "Open <BASE>/ua with the user agent set to ParityBot/1.0 and tell me the code it shows." Oracle: answer `UA-PARITY-OK`; log `ua ParityBot/1.0`.
37. `print-media`. `/print` has a block visible only in print media containing `PRINT-ONLY-8`. Prompt: "Open <BASE>/print. What text becomes visible when the page is rendered for print?" Oracle: answer `PRINT-ONLY-8`; log `print 1`.

## Performance, memory, and visuals

38. `slow-resource`. `/perf` loads four neutrally named assets (`/assets/r1.css`, `r2.js`, `r3.svg`, `r4.js`); only `r4.js` is delayed (1500 ms), so the name says nothing about speed. Prompt: "Open <BASE>/perf. Which resource slows the page load the most, and roughly how long does it take?" Oracle: answer `\br4\.js\b`.
39. `lcp-element`. `/lcp` has a large image (`id="i7"`, `/assets/p9.png`) and a small paragraph (`id="t3"`); no id or file name hints at the role. Prompt: "Open <BASE>/lcp. What is the Largest Contentful Paint element?" Oracle: answer names `i7` or `p9.png` and does not mention `t3`, so claiming the paragraph fails.
40. `memory-leak`. `/leak` has a button; each click creates 1000 objects of a class named `LeakyThing` kept in a global array and 100 detached DOM nodes. The class name is built from char codes (`String.fromCharCode`) and the class is created with `eval` at runtime, so the name is not in the page source; the heap snapshot reports it as the constructor. Prompt: "Open <BASE>/leak. Clicking the button leaks memory. Click it five times and tell me which object type is growing." Oracle: answer `LeakyThing`.
41. `screenshot-color`. `/visual` draws a canvas whose large square is pure red; the DOM does not say so. Prompt: "Open <BASE>/visual. What color is the large square drawn on the canvas?" Oracle: answer `\bred\b` (case-insensitive).
42. `cleanup`. Prompt: "Open <BASE>/a, read its heading, and make sure no browser, page, or tab is left open when you are done." Oracle: answer `Page A heading`; `toolCall`: a non-error call to `browser_close` (`browser`) or `safari_close_tab` (`safari`) that comes after the last `browser_open` (`safari`: the last `safari_navigate_to_url` or `safari_create_tab`). `chrome-devtools` has no browser-close tool and its `close_page` refuses to close the last page, so its pattern (`chrome-devtools_close_browser`) cannot match and the scenario fails by design: the server cannot reach the outcome. The earlier runner-side leftover check could not fail, because the runner killed pi's process group first and `browser` closes its browser on stdin end anyway. The runner now still samples descendants of pi every second and records in `result.json` (`leftover`) which browser processes were still alive 1.5 s after pi exited, sampled before the group kill, labeled informational; it never affects `pass`.

## Oracle notes

- ANSWER-line convention: `console-errors`, `failed-request` and `event-listener` ask for free text whose regex oracles kept accepting wrong answers and rejecting right ones across three review rounds. Their prompts now end with a fixed `ANSWER: ...` line, and the oracle checks only the last such line (`answerLine` in `scenarios.ts`), so the oracle judges a structured field instead of prose. The model-free reference solutions end with the same line.

- `viewport`, `dark-mode` and `print-media` also require a fixture log event that the page sends only when the emulated condition really matches, so reading the page source is not enough.
- `offline` checks the answer only: the page cannot report to the fixture server while it is offline, so an agent that reads the code from the page source instead of emulating passes. Treat a pass there as weak evidence.
- Process scoping: the runner and `verify.ts` only look at, and kill, descendants (by ppid) of the process they spawned, so other live sessions of the same MCP server are untouched. Playwright launches browsers detached, so they are children by ppid but not in the process group.
- Source-readable answers: `memory-leak`, `slow-resource`, `event-listener` and `lcp-element` used to have their answer in the page source (class name, asset name, listener code, `hero` ids). Their fixtures now expose it only at runtime. Runs record a `fixtureFingerprint` in `result.json`: a hash of the prompt, the scenario's served page, its answer-carrying assets (delay constant, PNG size and color, listener script) and the source of any handler-generated page template. `regrade.ts` prints "needs re-run" when a saved fingerprint differs from the current one, or when a run has no fingerprint and its id is in `FIXTURE_CHANGED`. A toolCall scenario with no saved `toolCallLog` also prints "needs re-run".
- `regrade.ts --batch DIR --server NAME` re-evaluates saved runs with the current oracles from each run's saved answer, `fixture-log.json` and tool call log, and prints old and new verdicts.
- `chrome-devtools-mcp` is pinned to `1.10.1` in `mcp/chrome-devtools.json` (the version that ran). Re-run `warm.ts` for it, since the adapter cache hash depends on the config.
