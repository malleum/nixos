{ config, ... }:
let
  inherit (config.unify) modules;

  hostName = "malleum";
in
{
  unify.hosts.nixos.${hostName} =
    { config, ... }:
    let
      inherit (config.user) username;
    in
    {
      modules = builtins.attrValues {
        inherit (modules)
          amd
          doc
          efi
          gam
          gui
          lap
          wrk
          ;
      };

      nixos.imports = [ ./_hardware-configuration.nix ];
      users.${username} = { inherit (config) modules; };
    };
}
