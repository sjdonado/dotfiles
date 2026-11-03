#!/usr/bin/env bash

# The first account is the primary account and the only account allowed to
# mutate shared macOS state. Keep real host and account names in this file only.
macos_hosts() {
  printf '%s\n' Juans-MacBook-Pro
}

macos_accounts_for_host() {
  case "$1" in
    Juans-MacBook-Pro) printf '%s\n' sjdonado juan ;;
    *) return 1 ;;
  esac
}

macos_primary_for_host() {
  macos_accounts_for_host "$1" | sed -n '1p'
}
