{
  config,
  lib,
  ...
}: let
  inherit (config.user) configHome;
  inherit (lib) mkOption types;
in {
  options.flakePath = mkOption {
    type = types.str;

    default = "${configHome}/nixos";
  };
}
