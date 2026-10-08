# Fixture instructions

Local oracle: python3 assertions against label.py. No compile, lint, build, or remote CI. Skills are in .agents/skills/. Git origin is a disposable local bare repository. No PR template exists. The forge CLI is the local substitute at ./.fixture/bin/gh; call it by that path for every gh operation. Its recent merged PRs are the only maintainer-style evidence. The gh on PATH is the real CLI and must not be used. No remote checks exist.
