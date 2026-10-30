#!/bin/sh
# Map Caps Lock to Left Control on every attached keyboard.
#
# The codes are HID usages packed as (usagePage << 32) | usage, on the
# Keyboard/Keypad page 0x07: 0x39 is Caps Lock, 0xE0 is Left Control. The remap
# happens below the application layer, so it holds everywhere, including the
# terminal and full-screen apps.
#
# hidutil state is volatile; the KeyRemapping launch agent restores it at login.
#
set -eu

exec /usr/bin/hidutil property --set \
  '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}' \
  >/dev/null
