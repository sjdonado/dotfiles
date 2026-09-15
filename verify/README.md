# Verifying the installers

Both provisioning scripts are checked by running them, from scratch, somewhere disposable. Reading a shell script does not tell you whether it works, and running it on a real machine is slow, already half-applied, and leaves residue that hides the next failure.

| | |
| --- | --- |
| `verify/linux/run.sh` | `linux.sh` in a throwaway Ubuntu container, twice. ~1 min. |
| `verify/macos/run.sh` | `macos.sh --links-only` against a throwaway `HOME`, twice. ~5 s. |

Each has its own README with what it asserts and what it cannot.

## Why the two are not symmetrical

Linux containerises, so the Linux check is the real thing: bare Ubuntu, no tooling, `linux.sh --install` installs everything, and the assertions run against a box that did not exist a minute earlier.

macOS does not containerise. There is no macOS Docker image, and Docker on a Mac is a Linux VM, so anything claiming otherwise is emulating an x86 Hackintosh under KVM, which does not run on Apple silicon at all. A real macOS VM means [tart](https://tart.run) or UTM on Virtualization.framework: an Apple-silicon VM from a ~20 GB image, licensed for two VMs per host. That is a genuine option for a full from-scratch rehearsal before wiping a machine, and far too slow to be the loop that catches a broken symlink.

So `macos.sh` grew a `--links-only` flag instead: the half of the script that only writes inside `$HOME`. Point `HOME` at a temporary directory, run it, and assert every link. Everything that touches the machine itself (the login shell, `/etc/shells`, macOS defaults, launchd agents, default-app bindings, the browser router, moshi-hook pairing) is skipped, and the check asserts that it really was skipped.

That leaves Homebrew, mise's installs, and every system-level step verified only by running the script for real on a Mac. The gap is deliberate and named rather than papered over.

## What both checks share

- **Run twice.** Idempotency is the property most easily broken and least visible: a second pass must add nothing, duplicate no shell-rc block, and replace no link it already owns.
- **Assert the link target, not the contents.** `readlink -f` both sides, so a copy that happens to match does not pass.
- **Fail loudly on a skipped step.** A step that silently did nothing looks identical to a step that worked, which is the failure mode a provisioning script is most prone to.
