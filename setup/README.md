# Provisioning

Root setup.sh bootstraps the repository; root sync.sh forwards to setup/sync.sh to apply, upgrade, check, or migrate it. Keep these entry points stable for existing bootstrap URLs and account orchestration. Running them can change the host.

- Brewfile declares macOS packages and applications.
- packages/linux-apt.txt declares Ubuntu packages. The TSV files document installer versions and provisioning coverage.
- lib/ implements links, installers, platform behavior, and migration.
- lib/hosts/macos.sh declares the primary and other accounts for each Mac.
- lib/shell/environment.sh provides the managed startup environment.
- macos/ contains OS defaults, launch-agent scripts and templates, keyboard layouts, and related platform notes.
- verify/ contains disposable provisioning checks, separate from agents/eval/ harness behavior checks.

Application configurations remain outside this folder in their root-level app directories. The link registry in setup/lib/links.sh connects them to each account's own checkout. The public bin/codex-config utility remains outside setup because its capture command is also used independently of provisioning.

## Verify before applying

From the repository root, run setup/verify/macos.sh for macOS changes and setup/verify/linux.sh for both linux/arm64 and linux/amd64 when Linux is affected. The platform guide is setup/verify/README.md. macOS uses temporary fixtures; Linux provisions containers. Report the completed assertions and anything unverified, not merely a zero process exit.

sync.sh --check inspects the real host. Applying, upgrading, migrating, or uninstalling changes host state and is separate from disposable verification. Existing Nix installations follow setup/lib/migration.md before removal. Package cleanup never targets personal data or secrets.
