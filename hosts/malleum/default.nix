{config, ...}: let
  inherit (config.unify) modules;

  hostName = "malleum";
in {
  unify.hosts.nixos.${hostName} = {config, ...}: let
    inherit (config.user) username;
  in {
    modules = builtins.attrValues {
      inherit
        (modules)
        bat
        cli
        gui
        cmp
        wrk
        ;
    };

    nixos.imports = [./hardware-configuration.nix];
    users.${username} = {inherit (config) modules;};
  };
}
