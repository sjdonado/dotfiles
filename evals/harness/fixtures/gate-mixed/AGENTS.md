# Fixture instructions

Local check: `python3 check.py`. Git origin is a disposable local bare repository and pushing to it is technically possible. The forge CLI is the local substitute at ./.fixture/bin/gh; call it by that path for every gh operation, never the real gh on PATH. No remote checks exist. Skills are in .agents/skills/.
