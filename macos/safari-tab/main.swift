// SafariTab: receives a URL and adds it as a tab to Safari's front window.
//
// LaunchServices opens Safari in a new window for every externally opened URL,
// whatever AppleWindowTabbingMode and Safari's TabCreationPolicy say, and routing
// through Finicky does not change that. Scripted tab creation is the only thing
// that produces a tab, so Finicky's default browser is this app.
//
// This was an AppleScript applet first. Applets are wrapped in a stub that shows
// AppleScript's startup screen ("Press Run to run this script, or Quit to quit")
// when launched from another app, so every link waited on a dialog. Removing the
// run handler did not help: the stub is the problem, not the script. A compiled
// binary has no stub.

import AppKit
import Foundation

private func openTab(_ url: String) {
    // Driving Safari through osascript rather than a raw Apple Event keeps this
    // short, and the TCC prompt is attributed to this app either way. The URL is
    // passed as an argument, never interpolated into the source, so a URL
    // containing quotes cannot alter the script.
    let script = """
    on run argv
        set theURL to item 1 of argv
        tell application "Safari"
            activate
            if (count of windows) is 0 then
                make new document with properties {URL:theURL}
            else
                tell front window to set current tab to (make new tab with properties {URL:theURL})
            end if
        end tell
    end run
    """

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    task.arguments = ["-e", script, url]
    try? task.run()
    task.waitUntilExit()
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    // The handler has to be registered before launch finishes: the URL event can
    // arrive as part of the launch itself.
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    // Launched with no URL, which is what happens if it is opened directly. There
    // is nothing to show, so leave rather than sit in the background.
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            NSApp.terminate(nil)
        }
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        guard let url = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue else {
            NSApp.terminate(nil)
            return
        }
        openTab(url)
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Accessory: no Dock icon, no menu bar, nothing to focus.
app.setActivationPolicy(.accessory)
app.run()
