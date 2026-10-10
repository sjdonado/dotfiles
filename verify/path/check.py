#!/usr/bin/env python3
"""Check the real provisioning PATH blocks against a legacy OpenCode install."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
linux = (root / "linux.sh").read_text().split('SHIMS="$HOME/.local/share/mise/shims"', 1)[1].split("rescan()", 1)[0]
linux = 'SHIMS="$HOME/.local/share/mise/shims"' + linux
fish = (root / "fish/config.fish").read_text().split("# Path configurations", 1)[1].split("# Aliases", 1)[0]
macos = (root / "macos.sh").read_text().split("# mise's shims directory", 1)[1].split("link_local_bin", 1)[0]
profile = (root / "linux.sh").read_text().split("# dotfiles: tools on PATH.", 1)[1].split("\nEOF", 1)[0]
profile = "# dotfiles: tools on PATH." + profile
fish_binary = shutil.which("fish")
if not fish_binary:
    raise SystemExit("fish is required for the PATH regression check")

with tempfile.TemporaryDirectory(prefix="dotfiles-path-") as temporary:
    home = Path(temporary)
    shims = home / ".local/share/mise/shims"
    legacy = home / ".opencode/bin"
    local_bin = home / ".local/bin"
    for directory in (shims, legacy, local_bin):
        directory.mkdir(parents=True)
    for directory, version in ((shims, "2.0.fixture"), (legacy, "1.0.fixture"), (local_bin, "1.0.local-fixture")):
        executable = directory / "opencode"
        executable.write_text(f"#!/bin/sh\nprintf 'opencode {version}\\n'\n")
        executable.chmod(0o755)
    for existing_shims in (False, True):
        path = [str(local_bin), str(legacy), "/usr/bin", "/bin"]
        if existing_shims:
            path.append(str(shims))
        environment = {"HOME": str(home), "BIN": str(local_bin), "PATH": os.pathsep.join(path), "XDG_CONFIG_HOME": str(home / ".config")}
        for name, command, source in (
            ("Linux bootstrap", ["/bin/bash", "-c"], linux + '\ncommand -v opencode'),
            ("macOS bootstrap", ["/bin/sh", "-c"], "# mise's shims directory" + macos + '\ncommand -v opencode'),
            ("POSIX profile", ["/bin/sh", "-c"], profile + '\ncommand -v opencode'),
            ("fish", [fish_binary, "--no-config", "-c"], fish + '\ntype -p opencode'),
        ):
            result = subprocess.run(command + [source], env=environment, text=True, capture_output=True, check=True)
            selected = result.stdout.strip()
            assert selected == str(shims / "opencode"), f"{name} selected legacy binary: {selected}"
            print(f"PASS: {name}, shims already on PATH={existing_shims}")
