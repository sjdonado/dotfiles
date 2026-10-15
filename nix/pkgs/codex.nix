# Codex, from the native build its npm package publishes per platform. nixpkgs compiles Codex from source, and Hydra's builds for aarch64-linux stopped finishing after 0.157, so a Linux arm box would compile it on every bump. Upgrade by changing `version` and the three hashes (each `@openai/codex@<version>-<platform>` package's `dist.integrity` on registry.npmjs.org).
#
# The Linux builds are static (musl), so they run on any distribution unpatched. The binary finds its bundled resources (codex-path/rg, codex-resources) next to its own real path, so the vendor directory is kept whole.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.162.1";
  platforms = {
    aarch64-darwin = {
      npm = "darwin-arm64";
      triple = "aarch64-apple-darwin";
      hash = "sha512-YVXpg57itBuQxjofay3KDF5UbnZF4Y1ZmNFzUCz0ZQiQN+DndxOjN5V87rnXvPaC4qCPO2El74DzewoBP8JyPQ==";
    };
    aarch64-linux = {
      npm = "linux-arm64";
      triple = "aarch64-unknown-linux-musl";
      hash = "sha512-Ss7W/SrKtQFNaMtSojNoiykJgX+iDC8daM+YrcvgmJADtQPk0cd3w6Dna4CYH2CYvf9nQranj69fpcTzZ3sQIQ==";
    };
    x86_64-linux = {
      npm = "linux-x64";
      triple = "x86_64-unknown-linux-musl";
      hash = "sha512-cjK2mdHIfEepZ1lQ1MX3aTQC+8ncIsvnacl/6vI2dIIcfP8/MrhTQ2+qRlkXFNDzJSj1d36quIszP+3/4CUJWQ==";
    };
  };
  platform = platforms.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;
  src = fetchurl {
    url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}-${platform.npm}.tgz";
    inherit (platform) hash;
  };
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;
  installPhase = ''
    mkdir -p $out/libexec $out/bin
    cp -R vendor/${platform.triple} $out/libexec/codex
    ln -s $out/libexec/codex/bin/codex $out/bin/codex
  '';
  meta = {
    description = "OpenAI Codex command-line agent";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames platforms;
    mainProgram = "codex";
  };
}
