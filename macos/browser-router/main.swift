// BrowserRouter: the default browser. Receives every link the system opens and
// routes it by destination.
//
// Finicky did this before and cost 131MB resident to do it: it embeds
// JavaScriptCore to evaluate its config, and the engine reserves ~95MB of heap
// arenas at launch whatever the config contains. Measured on a cold start with no
// links handled, so there was nothing to tune. The routing itself is two patterns
// and a default, which is this file. Nothing stays resident: the process handles
// one URL and exits.
//
// It has to be an app bundle declaring http/https, because only that receives the
// Apple Event carrying the URL.
//
// Safari is never opened directly. LaunchServices gives it a new window for every
// externally opened URL, whatever AppleWindowTabbingMode and Safari's
// TabCreationPolicy say, and going through a router does not change that. Scripted
// tab creation is the only thing that produces a tab, hence the AppleScript below.
//
// This was an AppleScript applet first. Applets are wrapped in a stub that shows
// AppleScript's startup screen ("Press Run to run this script, or Quit to quit")
// when launched from another app, so every link waited on a dialog. Removing the
// run handler did not help: the stub is the problem, not the script. A compiled
// binary has no stub.

import AppKit
import Foundation

// Local dev servers and Cloudflare preview deployments go to Helium, keeping
// Safari's session and extensions out of whatever is being tested. Everything else
// becomes a Safari tab.
private let heliumBundleID = "net.imput.helium"
private let heliumPatterns = [
    #"^https?://(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])(:\d+)?(/|$)"#,
    #"^https?://([^/]+\.)?(pages|workers)\.dev(/|$)"#,
]

private func goesToHelium(_ url: String) -> Bool {
    heliumPatterns.contains { pattern in
        url.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

private func openInHelium(_ url: String) -> Bool {
    guard let target = URL(string: url),
          let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: heliumBundleID)
    else { return false }

    // Synchronous, because the process exits as soon as this returns: an async
    // open would be cancelled with it. The semaphore waits for LaunchServices to
    // acknowledge the open, not for the page to load.
    let config = NSWorkspace.OpenConfiguration()
    config.activates = true
    var launched = false
    let done = DispatchSemaphore(value: 0)
    NSWorkspace.shared.open([target], withApplicationAt: app, configuration: config) { _, error in
        launched = error == nil
        done.signal()
    }
    _ = done.wait(timeout: .now() + 10)
    return launched
}

private func openSafariTab(_ url: String) {
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

private func route(_ url: String) {
    // A failed Helium open falls through to Safari rather than dropping the link:
    // Helium not being installed should cost the preview split, not the click.
    if goesToHelium(url), openInHelium(url) { return }
    openSafariTab(url)
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
        route(url)
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Accessory: no Dock icon, no menu bar, nothing to focus.
app.setActivationPolicy(.accessory)
app.run()
