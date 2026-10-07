#!/bin/sh
# macOS App Shortcuts (System Settings > Keyboard > Keyboard Shortcuts > App Shortcuts).
# Each app's dictionary and the list of apps are replaced, not merged, so this file is the whole set: a shortcut added in System Settings for a listed app is dropped on the next run, and one for an unlisted app keeps working but disappears from the App Shortcuts pane.
# Encoding: @=Cmd $=Shift ~=Opt ^=Ctrl. A title must match its menu item exactly. Apps pick up changes when relaunched.
set -eu

# Sandboxed apps and the Accessibility domain fail with a permissions error unless the running terminal has Full Disk Access.
shortcuts() {
  domain=$1
  shift
  defaults write "$domain" NSUserKeyEquivalents -dict "$@" ||
    echo "  ! skipped $domain shortcuts (on a permissions error, grant Full Disk Access to the terminal, then rerun)"
}

shortcuts -g "Show Help menu" '@$/' "Zoom In" '@=' "Zoom Out" '@-' "Actual Size" '@0'
# "..." matches the menu's "…" title: the binding below is live with it. Cmd-S for the sidebar replaces Safari's Save As.
shortcuts com.apple.Notes "Note List Search..." '@k' "Show Sidebar" '@s' "Hide Sidebar" '@s'
shortcuts com.apple.Safari "Show Sidebar" '@s' "Hide Sidebar" '@s'
shortcuts com.apple.reminders "Show Sidebar" '@s' "Hide Sidebar" '@s'

# The apps System Settings lists under App Shortcuts.
defaults write com.apple.universalaccess com.apple.custommenu.apps -array NSGlobalDomain com.apple.Notes com.apple.Safari com.apple.reminders ||
  echo "  ! skipped the App Shortcuts app list (on a permissions error, grant Full Disk Access to the terminal, then rerun)"

# Reload the preferences daemon so changes take effect without logging out.
killall cfprefsd 2>/dev/null || true
