# BrowserRouter

The default browser. Every link the system opens arrives here and is routed by destination: local dev servers and Cloudflare preview deployments to Helium, everything else to a new tab in Safari's front window.

It is an app bundle because only a bundle declaring `http`/`https` receives the Apple Event carrying the URL. `macos.sh` compiles, signs and registers it into `~/Applications/BrowserRouter.app`. macOS will not let a script make it the default browser, so that is confirmed once by hand.

## Footprint

Measured on this machine, macOS 26, Apple silicon.

| | |
| --- | --- |
| bundle on disk | 92 KB, three files |
| source | 168 lines |
| memory while routing a link | 7.2 MB private footprint, 31 MB RSS |
| memory at rest | none, no process |
| process lifetime per link | 0.18s to Helium, 0.34s to a Safari tab |

RSS is the number Activity Monitor shows and most of it is shared AppKit pages counted against every process that links the framework; the private footprint is what this app actually costs. The Safari path also spawns `osascript` for its lifetime, another ~26 MB RSS, because scripted tab creation is the only way to land a link in a tab rather than a new window. The Helium path spawns nothing.

## Why not Finicky

Finicky did this routing from a JS config and cost **131 MB resident**, permanently, to run two regexes and a default.

That is not its config's fault and there is nothing to tune. Finicky embeds JavaScriptCore, and the engine reserves its heap at launch: a cold start with no links handled measured 130.9 MB, of which 95.5 MB was 121 four-megabyte `rw-/rwx` arenas. There was no leak either. A process nine days old with about 200 links behind it measured *smaller*, 121 MB, because macOS had compressed the idle heap.

It also cost a hop. Finicky evaluated the URL in ~56 ms and then ran `open -b <the handler bundle id> <url>`, launching the app that did the actual work. That app is this one, so folding two patterns into it removed the resident engine, the hop and a 27 MB cask download.

## Editing the routing

The patterns live at the top of `main.swift`. Changing them means a recompile, which `macos.sh` does:

```sh
./macos.sh
```

A link is the test: `open https://example.com` should land as a Safari tab, `open http://localhost:3000` should land in Helium. A failed Helium open falls back to Safari rather than dropping the link, so a missing Helium costs the preview split, not the click.

## Gotchas

**Declaring the URL schemes is not enough to become the default browser.** `NSWorkspace.setDefaultApplication` fails with "The file couldn't be opened" (`NSCocoaErrorDomain` 256) until the bundle also claims to *view* HTML. `Info.plist` therefore declares `CFBundleDocumentTypes` for `public.html`, `public.xhtml` and `public.url` that the app never opens.

Isolated on a throwaway bundle rather than inferred: same binary, same ad-hoc signature, same `lsregister -f`, one key different. Without the document types the call failed; with them it returned OK. Re-register after editing `Info.plist`, or LaunchServices answers from what it cached.

**Setting `http` sets `https` too.** One call moves both, and calling again for the second scheme returns the same "file couldn't be opened" error even though the state is already correct. Set `http` and verify rather than looping over the pair.

**It cannot be an AppleScript applet.** Applets are wrapped in a stub that shows AppleScript's startup screen when another app launches them, so every link waited on a dialog. Deleting the run handler does not help: the stub is the problem, not the script.

**Safari is never opened directly.** LaunchServices gives it a new window for every externally opened URL whatever `AppleWindowTabbingMode` and Safari's own tab preference say. Scripted tab creation is the only thing that produces a tab.
