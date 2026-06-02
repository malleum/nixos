{config, ...}: let
  inherit (config.unify) modules;

  hostName = "minimus";
in {
  unify.hosts.nixos.${hostName} = {config, ...}: let
    inherit (config.user) username;
  in {
    modules = builtins.attrValues {
      inherit
        (modules)
        cache-server
        efi
        grapple
        matrix
        wordle-bot
        ;
    };

    nixos.imports = [
      ./_hardware-configuration.nix
      ./_network.nix
      ./_server.nix
    ];
    users.${username} = {inherit (config) modules;};
  };
}
