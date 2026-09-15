#!/bin/sh
# Prints the guest password for SSH_ASKPASS (see run.sh). Throwaway lab VMs
# only: the password travels in this process's environment, never on a tty.
printf '%s\n' "$GUEST_PASSWORD"
