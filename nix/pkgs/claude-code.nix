# Claude Code on macOS, from Anthropic's release binary instead of nixpkgs, which trails the releases: T3 Code checks the installed version against the latest and flags an older one as outdated, and its update button runs Claude's own updater, which cannot replace a Nix build. Upgrade by changing `version` and `sha256` to the `darwin-arm64` entry of https://downloads.claude.ai/claude-code-releases/<version>/manifest.json (the current version is at .../claude-code-releases/latest).
#
# Linux keeps nixpkgs `claude-code` (nix/home/common.nix).
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
}:
let
  version = "2.1.302";
in
stdenvNoCC.mkDerivation {
  pname = "claude-code";
  inherit version;
  src = fetchurl {
    url = "https://downloads.claude.ai/claude-code-releases/${version}/darwin-arm64/claude";
    sha256 = "5262ce9de86243fed0d21edc39b271555d56780d0112e2b194439fe1c6662d37";
  };
  nativeBuildInputs = [ makeWrapper ];
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  # The binary is a signed single-file executable; stripping or patching it breaks it.
  dontFixup = true;
  # As nixpkgs' build does: Nix owns the binary, so Claude must not update or reinstall itself.
  installPhase = ''
    install -Dm755 $src $out/libexec/claude
    makeWrapper $out/libexec/claude $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1
  '';
  meta = {
    description = "Anthropic's agentic coding tool";
    homepage = "https://github.com/anthropics/claude-code";
    license = lib.licenses.unfree;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "claude";
  };
}
