# Keep background tasks process-only and use Bash syntax regardless of login shell.
set -gx PI_BG_FEATURES process
set -gx PI_BG_POSIX_SHELL bash
