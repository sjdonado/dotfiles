# Verifying linux.sh in a container

`linux.sh` provisions a remote box. That makes it the one script here with no cheap feedback loop: running it on a real machine is slow, half of it is already done on any box worth testing on, and a failure leaves residue that hides the next failure.

So it gets a throwaway box instead.

```sh
verify/linux/run.sh
```

That builds a bare Ubuntu 24.04, copies this working tree in (uncommitted changes included), runs `linux.sh --install` from scratch, asserts the result, runs it a second time, asserts again, and checks that the second pass did not duplicate anything in the shell startup files. It takes about a minute on a warm image and prints `all checks passed` or the first thing that broke.

| | |
| --- | --- |
| `verify/linux/run.sh --platform linux/amd64` | Same run on the other architecture. Slower, emulated on Apple silicon. |
| `verify/linux/run.sh --shell` | Provision, then hand you a shell inside the finished box. |

## What it asserts

`verify.sh` is the whole contract, in four groups, because those are the four ways this breaks:

- **Every tool runs.** Not "is on PATH": `--version` has to answer. A wrapper whose postinstall never ran is on PATH and still broken, which is the exact failure that keeps Claude Code out of `mise.toml`.
- **Every tracked config is linked** to the file in this repository, resolved through `readlink -f`, so a copy that happens to have the same contents does not pass.
- **Non-interactive shells resolve the tools.** A login `bash -lc`, and a bare shell that sources only `~/.profile`. This is what an agent hook or a herdr pane gets, and it is where the first version of this failed: Ubuntu's `~/.bashrc` returns immediately for non-interactive shells, so everything appended to it was invisible. Environment moved to `~/.profile` and `~/.zshenv` because of this check.
- **The tracked git identity wins**, rather than an injected `GIT_AUTHOR_*`.

## GitHub rate limits

The unauthenticated GitHub API allows 60 requests an hour per IP, and every tool installed from a GitHub release spends a couple. `run.sh` passes `gh auth token` into the container when there is one; without it, a shared or busy IP produces 403s that have nothing to do with the change being tested. The symptom is `failed: ... 403 Forbidden` from mise, or an installer reporting that it cannot fetch version information.

## What it does not cover

macOS, which cannot be containerised at all. `verify/macos/run.sh` covers what a sandboxed `HOME` can, and `verify/README.md` explains the asymmetry.

Nor does it prove the box is usable in anger: nothing authenticates, no agent runs a session, herdr never starts a server. It proves provisioning is complete, linked, idempotent, and on PATH.
