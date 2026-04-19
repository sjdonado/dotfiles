#!/bin/sh
# Set macOS app shortcuts (System Settings → Keyboard → Keyboard Shortcuts → App Shortcuts)
# Encoding: @=Cmd $=Shift ~=Opt ^=Ctrl. Uppercase letter implies Shift.
set -eu

# All Applications — stored in NSGlobalDomain
defaults write -g NSUserKeyEquivalents -dict-add "Show Help menu"            '@$/'
defaults write -g NSUserKeyEquivalents -dict-add "Zoom In"                   '@='
defaults write -g NSUserKeyEquivalents -dict-add "Zoom Out"                  '@-'
defaults write -g NSUserKeyEquivalents -dict-add "Actual Size"               '@0'
defaults write -g NSUserKeyEquivalents -dict-add "Open sidebar"              '@`'
defaults write -g NSUserKeyEquivalents -dict-add "Close sidebar"             '@.'
defaults write -g NSUserKeyEquivalents -dict-add "Hide sidebar"              '@`'
defaults write -g NSUserKeyEquivalents -dict-add "Hide Sidebar"              '@`'
defaults write -g NSUserKeyEquivalents -dict-add "Hide Folders"              '@`'
defaults write -g NSUserKeyEquivalents -dict-add "Show Folders"              '@`'
defaults write -g NSUserKeyEquivalents -dict-add "Show Sidebar"              '@`'
defaults write -g NSUserKeyEquivalents -dict-add "Show sidebar"              '@`'
defaults write -g NSUserKeyEquivalents -dict-add "Show/Hide Sidebar"         '@`'
defaults write -g NSUserKeyEquivalents -dict-add "Toggle sidebar"            '@`'
defaults write -g NSUserKeyEquivalents -dict-add "Toggle Sidebar"            '@`'
defaults write -g NSUserKeyEquivalents -dict-add "Toggle Left Sidebar"       '@.'
defaults write -g NSUserKeyEquivalents -dict-add "Expand navigation sidebar" '@`'

# Notes.app
defaults write com.apple.Notes NSUserKeyEquivalents -dict-add "Note List Search..." '@k'

# Reload prefs daemon so changes take effect without logout
killall cfprefsd 2>/dev/null || true
