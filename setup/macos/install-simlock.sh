#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname -s)" != Darwin ] || [ "$(id -u)" -eq 0 ]; then
  printf 'Run this as the macOS account that will host the pool.\n' >&2
  exit 1
fi

source_config="$(cd "$(dirname "$0")" && pwd)/simlock.json"
export SIMLOCK_HOME="$HOME/.simlock"
install_root="$HOME/.local/share/simlock"
simlock="$install_root/node_modules/.bin/simlock"
simlock_version=0.8.0
agent_device_version=0.21.36
agent_device_package="$install_root/node_modules/agent-device/package.json"
export PATH="$install_root/node_modules/.bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
unset ANDROID_HOME ANDROID_SDK_ROOT
umask 077

xcrun simctl list -j runtimes | node -e '
  const { readFileSync } = require("node:fs");
  const { runtimes } = JSON.parse(readFileSync(0, "utf8"));
  const { targets } = require(process.argv[1]).warmPool;
  for (const { model, osVersion } of targets) {
    const supported = runtimes.some((runtime) =>
      runtime.isAvailable && runtime.version === osVersion &&
      runtime.supportedDeviceTypes?.some((device) => device.name === model));
    if (!supported) {
      console.error(`Install an available iOS ${osVersion} simulator runtime that supports ${model}.`);
      process.exitCode = 1;
    }
  }
' "$source_config"

if [ -e "$SIMLOCK_HOME/config.json" ] && ! cmp -s "$source_config" "$SIMLOCK_HOME/config.json"; then
  printf 'Existing SimLock configuration differs. Review %s before changing the running pool.\n' "$SIMLOCK_HOME/config.json" >&2
  exit 1
fi

if [ ! -x "$simlock" ] || [ "$("$simlock" --version)" != "$simlock_version" ] ||
   [ ! -f "$agent_device_package" ] ||
   ! node -e 'process.exit(require(process.argv[1]).version === process.argv[2] ? 0 : 1)' "$agent_device_package" "$agent_device_version"; then
  npm install --prefix "$install_root" --no-audit --no-fund --save-exact "simlock@$simlock_version" "agent-device@$agent_device_version"
fi

mkdir -p "$SIMLOCK_HOME"
if [ ! -e "$SIMLOCK_HOME/config.json" ]; then
  (set -o noclobber; cat "$source_config" > "$SIMLOCK_HOME/config.json")
fi

if [ -e "$HOME/Library/LaunchAgents/com.callstack.simlock.worker.plist" ]; then
  "$simlock" daemon start
else
  "$simlock" daemon install
fi
