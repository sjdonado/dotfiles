# OpenCode v2, from the native binary its npm package publishes per platform. nixpkgs still carries v1, and this setup runs v2 (opencode/README.md). Upgrade by changing `version` and the three hashes (each package's `dist.integrity` on registry.npmjs.org).
#
# No ELF patching on Linux: the binary is a Bun single-file executable, which reads its bundle back from its own file, and the boxes this targets are distributions that have the system loader it names.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "2.0.27";
  platforms = {
    aarch64-darwin = {
      npm = "darwin-arm64";
      hash = "sha512-0BAaNYZE5QKve/7EFw9gyTQpkyOdff7Lj8Eul6FwK1vDnkj+yiVt/gdmJZl0PVoexl+6ZhjB7vuUPgSXrRATtA==";
    };
    aarch64-linux = {
      npm = "linux-arm64";
      hash = "sha512-qK2E8iy7ZyOC1RcbJZuVuzUHHDwg4BxgE405+bPLZjep0cU2yqvifsVB0UptyiVs2GxXfZDbmn2w7y5PW49ssg==";
    };
    x86_64-linux = {
      npm = "linux-x64";
      hash = "sha512-QPGrzBSSs5ATG3nM4XjS4tmWXUB22Di36H0vfMuhKwk6i3PR3Nb4sm+l00gvTdcyCRohYsKwqjvD67T0DPcQLQ==";
    };
  };
  platform = platforms.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "opencode";
  inherit version;
  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode/cli-${platform.npm}/-/cli-${platform.npm}-${version}.tgz";
    inherit (platform) hash;
  };
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;
  installPhase = ''
    install -Dm755 bin/opencode $out/bin/opencode
  '';
  meta = {
    description = "OpenCode v2 command-line agent";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    platforms = builtins.attrNames platforms;
    mainProgram = "opencode";
  };
}
