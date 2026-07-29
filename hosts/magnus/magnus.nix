{config, ...}: let
  inherit (config.unify) modules;

  hostName = "magnus";
in {
  unify.hosts.nixos.${hostName} = {config, ...}: let
    inherit (config.user) username;
  in {
    modules = builtins.attrValues {
      inherit
        (modules)
        ai
        amd
        bt-audio
        cht
        dbt
        dev
        doc
        efi
        gam
        gui
        hyp
        med
        off
        prn
        src
        vrt
        wrk
        ;
    };

    nixos.imports = [./_hardware-configuration.nix];
    users.${username} = {inherit (config) modules;};
  };
}
