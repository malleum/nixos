# iogii, the golfscript.com interpreter. A single Ruby file behind a wrapper.
#
# Was an inline mkDerivation in modules/packages/programming.nix. Moving it out
# fixed two things:
#
#   * The old wrapper was written with an unquoted, indented heredoc, so the
#     file began with four spaces before `#!/bin/sh`. A shebang is only a
#     shebang at byte 0, so execve returned "Exec format error" -- `iogii`
#     worked when typed at a prompt (the shell falls back to interpreting it)
#     but not from `#!/usr/bin/env iogii`, `exec iogii`, or any subprocess call
#     that does not go through a shell. makeWrapper emits a correct one.
#
#   * builtins.fetchurl runs during *evaluation*, so evaluating any host with
#     the `dev` module wanted the file present or the network reachable.
#     pkgs.fetchurl builds a derivation and defers the download.
{
  perSystem = {pkgs, ...}: let
    version = "1.2";

    src = pkgs.fetchurl {
      url = "https://golfscript.com/iogii/iogii-${version}";
      sha256 = "1kgvr7jzayrcdm1wqk3pzl8lyjp317rk7vndwws3dl2x6ikbc2xn";
    };

    iogii =
      pkgs.runCommand "iogii-${version}" {
        nativeBuildInputs = [pkgs.makeWrapper];
        meta = {
          description = "Interpreter for the iogii golfing language";
          homepage = "https://golfscript.com/iogii/";
          mainProgram = "iogii";
        };
      } ''
        mkdir -p $out/share/iogii
        cp ${src} $out/share/iogii/iogii
        makeWrapper ${pkgs.ruby}/bin/ruby $out/bin/iogii \
          --add-flags $out/share/iogii/iogii
      '';
  in {
    packages.iogii = iogii;

    apps.iogii = {
      type = "app";
      program = "${iogii}/bin/iogii";
    };
  };
}
