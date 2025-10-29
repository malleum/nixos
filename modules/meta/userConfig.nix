{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;

  email = "jph33@outlook.com";
  name = "Josh Hammer";
  username = "joshammer";
  gitusername = "malleum";
  homeDirectory = "/home/${username}";
  configHome = "${homeDirectory}/.config";
in {
  options.user = mkOption {
    type = types.attrsOf types.str;
    default = {inherit email name username homeDirectory configHome gitusername;};
  };

  config.unify.options.user = mkOption {
    type = types.attrsOf types.str;
    internal = true;
    default = config.user;
  };
}
