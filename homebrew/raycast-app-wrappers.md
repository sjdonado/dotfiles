# Make Homebrew CLI binaries visible to Raycast

Raycast's **Settings -> Applications** list is built from LaunchServices, which only indexes `.app` bundles. A Homebrew formula that installs a plain binary into `/opt/homebrew/bin` therefore never appears there, so it cannot be given a hotkey or an alias, even when the running program shows its own name in the menu bar.

The fix is a minimal `.app` bundle that wraps the binary. The example below uses `scrcpy`, which ships as a CLI that opens a GUI window.

## The rule that makes the hotkey toggle

The bundle's `CFBundleExecutable` must **be** the binary, reached by a symlink inside `Contents/MacOS`. Do not use a shell script that `exec`s the binary from `/opt/homebrew/bin`.

A launcher script works for starting the app but breaks toggling. Raycast's application hotkey activates the running instance whose bundle identifier matches, and hides it on a second press. When the launcher `exec`s an executable that lives outside the bundle, the process ends up bound to the Homebrew path rather than to the bundle, so Raycast finds nothing running and launches another copy on every press.

With a symlinked executable, LaunchServices keeps `bundleID=local.wrapper.NAME` on the process and the hotkey toggles like any other app. Verify with `lsappinfo list | grep -A3 local.wrapper`.

Homebrew binaries link their dylibs by absolute path (`/opt/homebrew/opt/...`), so running one through a symlink in a foreign directory resolves fine. Check with `otool -L BINARY` if a tool misbehaves.

## 1. Build the wrapper

```bash
APP_NAME=scrcpy                          # bundle and Raycast display name
BIN=/opt/homebrew/bin/scrcpy             # target binary
ICON_PNG=/opt/homebrew/opt/scrcpy/share/icons/hicolor/256x256/apps/scrcpy.png

APP="/Applications/$APP_NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
ln -s "$BIN" "$APP/Contents/MacOS/$APP_NAME"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>local.wrapper.$APP_NAME</string>
  <key>CFBundleIconFile</key><string>$APP_NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSEnvironment</key>
  <dict>
    <key>PATH</key><string>/opt/homebrew/bin:$HOME/Library/Android/sdk/platform-tools:/usr/bin:/bin</string>
    <key>ADB</key><string>$HOME/Library/Android/sdk/platform-tools/adb</string>
  </dict>
</dict>
</plist>
EOF
```

`LSEnvironment` replaces what a launcher script used to do. Apps started from Raycast, Finder, or Spotlight inherit a bare environment, not the shell's, so anything the binary shells out to (`adb` here, `ffmpeg`, `node`, any other Homebrew tool) fails to resolve. List only the directories the tool needs, and prefer an explicit variable the tool documents (`ADB` for scrcpy) over relying on `PATH` alone.

LaunchServices caches `LSEnvironment` at registration, so re-run step 3 after editing it.

## 2. Add an icon

Skipping this leaves a blank page icon in Raycast and the Dock. Most formulae ship a PNG under `share/icons`:

```bash
ICONSET=$(mktemp -d)/icon.iconset
mkdir -p "$ICONSET"
for s in 16 32 128 256; do
  sips -z $s $s "$ICON_PNG" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$ICON_PNG" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/$APP_NAME.icns"
```

Find the source PNG with `find "$(brew --prefix FORMULA)" -iname '*.png'`. When a formula ships none, any square PNG works.

## 3. Register with LaunchServices

```bash
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
```

Without this the bundle can sit in `/Applications` for minutes before macOS notices it.

## 4. Verify, then bind the hotkey

Open it twice and confirm only one process exists:

```bash
open -a "/Applications/$APP_NAME.app"; sleep 5
open -a "/Applications/$APP_NAME.app"; sleep 3
pgrep -f "$APP_NAME" | wc -l
lsappinfo list | grep -c "bundleID=\"local.wrapper.$APP_NAME\""
```

A second process, or a count of zero matching bundle entries, means the executable is not resolving to the bundle. Re-check `CFBundleExecutable` and the symlink.

Then in Raycast: **Settings -> Applications**, search the name, **Record Hotkey**. If the row is missing, use **Settings -> Advanced -> Reindex applications**, or restart Raycast.

## Notes

- An instance started from a terminal has no bundle identifier, so the hotkey ignores it and starts a bundled one alongside. Launch through the app if you want the hotkey to reach it.
- `brew upgrade` keeps working, because the symlink points at `/opt/homebrew/bin` rather than a versioned Cellar path. `brew uninstall` leaves a dangling symlink and a dead bundle, so remove it by hand.
- The bundle is unsigned. If Gatekeeper blocks the first launch, right-click the app and choose **Open** once.
- Default arguments have nowhere to live in this layout, since there is no script. When a tool needs them, use its own config file or environment variables via `LSEnvironment`. Falling back to a launcher script costs the hotkey toggle.
- For a CLI with no GUI window, use a Raycast Script Command instead. Reach for a bundle only when the binary opens a window of its own.
- Wrappers live in `/Applications` and are not tracked by this repo. Rebuild them after a machine reset.

## Built on this machine

| App | Binary | Notes |
| --- | --- | --- |
| `scrcpy` | `/opt/homebrew/bin/scrcpy` | `ADB` and `PATH` set via `LSEnvironment` for `platform-tools` |
