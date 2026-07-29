# cls, from the malleum/cls flake input. Exposed as a flake package so it can
# be `nix run .#cls`'d, and consumed by modules/packages/cli.nix.
#
# Previously lived in modules/meta/nvim.nix, which had nothing to do with it.
{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    cls = inputs.cls.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    packages.cls = cls;

    apps.cls = {
      type = "app";
      program = "${cls}/bin/cls";
    };
  };
}
