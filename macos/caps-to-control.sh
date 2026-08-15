#!/bin/sh
# Map Caps Lock to Left Control on every attached keyboard.
#
# The codes are HID usages packed as (usagePage << 32) | usage, on the
# Keyboard/Keypad page 0x07: 0x39 is Caps Lock, 0xE0 is Left Control. The remap
# happens below the application layer, so it holds everywhere, including the
# terminal and full-screen apps.
#
# hidutil state is volatile: it does not survive a logout or reboot, which is why
# com.local.KeyRemapping.plist runs this at every login rather than once at setup.
#
# This exists as a script rather than as hidutil arguments in the plist so Login
# Items, which names a background item after the executable it launches, shows
# caps-to-control.sh instead of a bare "hidutil".
set -eu

exec /usr/bin/hidutil property --set \
  '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}' \
  >/dev/null
