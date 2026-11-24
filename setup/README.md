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

## Shared mobile device pool

Install both iOS 27.2 simulator runtimes. The standard build serves iPhone and iPad, and iPhone Duo has its own build.

```sh
xcodebuild -downloadPlatform iOS -buildVersion 24B8117
xcodebuild -downloadPlatform iOS -buildVersion 24B91016s
setup/macos/install-simlock.sh
```

Run the installer as the logged-in macOS account that hosts the T3 device source. It verifies runtime compatibility, installs SimLock 0.8.0 with agent-device 0.21.36, writes the worker config on first install, and registers SimLock's login service. The worker listens at `http://127.0.0.1:4701` and keeps its simulators in a private device set. SimLock runtime downloads and physical-device enrollment are off.

In T3, enable **Settings → Labs → Simlock device hosts** and add the worker under **Settings → Devices → Add source → Simlock pool**. Name it **Shared iOS SimLock** and enter `http://127.0.0.1:4701`. Use an agent token from `~/.local/share/simlock/node_modules/.bin/simlock token create --role agent --label T3`, stored through T3's secret input. Set **Devices at once** to three and use a T3 build whose required agent-device version matches the worker. Use the pool's catalog entries for **iPhone 17**, **iPhone 18 Pro**, **iPad (A16)**, and **iPhone Duo**. Check that the lease reports iOS 27.2. For two projects that each need an iPhone, request a catalog entry from each thread. They can request the same model or different models within the shared limit. T3 requests the model, and the worker selects its newest compatible installed runtime.

For Android, install the Android Emulator, Platform-Tools, Command-line Tools, and Android 16 (API 36) Google APIs ARM64 system image in the local Android SDK. Select **Pixel 8** from the same SimLock source and confirm the lease reports Android API 36.

SimLock caps the worker at three running devices, including at most one Android emulator, and boots on demand. Prewarming is disabled to avoid idle load. The worker still advertises other available models, and an iOS model can use multiple slots. T3 still offers its local device source. SimLock leases a single device, creates a fresh identity after release, and has no atomic iPhone–Apple Watch lease.

## Verify before applying

From the repository root, run setup/verify/macos.sh for macOS changes and setup/verify/linux.sh for both linux/arm64 and linux/amd64 when Linux is affected. The platform guide is setup/verify/README.md. macOS uses temporary fixtures; Linux provisions containers. Report the completed assertions and anything unverified, not merely a zero process exit.

sync.sh --check inspects the real host. Applying, upgrading, migrating, or uninstalling changes host state and is separate from disposable verification. Existing Nix installations follow setup/lib/migration.md before removal. Package cleanup never targets personal data or secrets.
