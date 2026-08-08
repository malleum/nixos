{config, ...}: let
  inherit (config.unify) modules;

  hostName = "minoris";
in {
  unify.hosts.nixos.${hostName} = {config, ...}: let
    inherit (config.user) username;
  in {
    # Minimal usable laptop. Add as needed:
    #   amd / wif  hardware quirks      hyp  hyprland as a second session
    #   dev        toolchains           cht  matrix + signal
    #   gam        games                med  players, obs, spotify
    #   off        libreoffice          ai   assistant CLIs
    #   doc        docker               vrt  qemu / quickemu
    #   wrk        work tooling         src  build jay+iamb from source
    modules = builtins.attrValues {
      inherit
        (modules)
        efi
        gui
        lap
        ;
    };

    nixos.imports = [./_hardware-configuration.nix];
    users.${username} = {inherit (config) modules;};
  };
}
