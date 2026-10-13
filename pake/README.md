# Pake apps

Work web apps (Linear first; Slack, Notion, Gmail, Calendar and Meet next) run as single-site desktop apps built with [Pake](https://github.com/tw93/Pake), which wraps a site in a Tauri app on the system WebKit view. BrowserRouter sends each app's links to it, so a link clicked anywhere opens in the window that is already showing that app, not in a new browser tab.

Every app is built from a local Pake clone with two patches applied, until upstream has an equivalent:

- `open-links-in-window.diff`: upstream Pake focuses an app that receives a link but drops the link. With the patch, on macOS, a link another app opens with a Pake app (`open -b <bundle id> <url>`, which is what BrowserRouter does) loads in the existing main window, which is then shown and focused.
- `follow-system-appearance.diff`: upstream Pake sets the window theme from the page's own theme markers. On macOS the window theme is also the page's `prefers-color-scheme`, so a page that forces dark (Linear's signed-out homepage is `<html data-theme="dark">`) locks every later page that follows the system into dark. With the patch, on macOS, the window keeps the system appearance. Other platforms are unchanged, and an app built with `--dark-mode` is still dark.

## Requirements

- Rust (`rustup`) and Xcode command line tools.
- Node and pnpm, both from mise.toml.
- BrowserRouter installed and set as the default browser (see the root README, "Default browser").

## Build Pake with the patch, once

The patches were made against Pake commit `3a344f5` (V3.17.4). A later Pake usually still accepts them. When `git apply --check` fails, re-apply the change by hand: the link handler goes in `src-tauri/src/lib.rs`, in the `.run(...)` closure next to the `RunEvent::Reopen` handler, and the appearance change is `update_theme_mode` in `src-tauri/src/app/invoke.rs`.

```sh
git clone https://github.com/tw93/Pake.git ~/Developer/Pake
cd ~/Developer/Pake
git apply --check ~/.config/dotfiles/pake/*.diff
git apply ~/.config/dotfiles/pake/*.diff
pnpm install --frozen-lockfile
pnpm run cli:build
```

`pnpm run cli:build` writes `dist/cli.js`, the CLI that builds apps from this clone's `src-tauri`, patches included.

## Create an app

Run from the Pake clone. Use the site's signed-in start page as the URL, and give every app an identifier under `dev.local.pake.`, so the router rules and this list stay predictable.

```sh
node dist/cli.js https://linear.app --name Linear --identifier dev.local.pake.linear --iterative-build
```

`--iterative-build` builds only the `.app`, with no disk image. A release build takes a few minutes. The result is `~/Developer/Pake/Linear.app`.

Install and register it:

```sh
rm -rf ~/Applications/Linear.app
cp -R ~/Developer/Pake/Linear.app ~/Applications/
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ~/Applications/Linear.app
```

Open it once and sign in. Each Pake app has its own WebKit data store, so sessions are not shared with Safari, Search or another Pake app.

## Route its links

Add a rule to `macos/browser-router.json`, above any broader rule that matches the same host (the first match wins):

```json
{
  "match": "^https?://([^/]+\\.)?linear\\.app(/|$)",
  "browser": "dev.local.pake.linear"
}
```

BrowserRouter reads the config on every link, so the rule applies to the next click with no restart. Check it with `open "https://linear.app/<workspace>/team/<key>/documents"`: the app comes forward on that page, both when it was running on another page and when it was closed.

## Apps

| App | URL | Identifier | Status |
| --- | --- | --- | --- |
| Linear | `https://linear.app` | `dev.local.pake.linear` | built, routed |
| Slack | `https://app.slack.com` | `dev.local.pake.slack` | not built; routed to Search |
| Notion | `https://www.notion.so` | `dev.local.pake.notion` | not built; routed to Search |
| Gmail | `https://mail.google.com` | `dev.local.pake.gmail` | not built; routed to Search |
| Calendar | `https://calendar.google.com` | `dev.local.pake.calendar` | not built; routed to Search |
| Meet | `https://meet.google.com` | `dev.local.pake.meet` | not built; routed to Search |

## Known issues

- Each app keeps its own WebKit process running while open, with no sleeping tabs as in Search.
- A link that arrives while the app is still loading its first page can be replaced by that page's own redirect. Seen once with Linear: `/homepage` opened, then a workspace link sent 8 seconds later showed the last-visited project instead. The same link sent to the running app opened the right page. Cause not confirmed.
