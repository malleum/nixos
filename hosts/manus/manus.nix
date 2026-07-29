{
  config,
  inputs,
  ...
}: let
  inherit (config.unify) modules;

  hostName = "manus";
in {
  unify.hosts.nixos.${hostName} = {config, ...}: let
    inherit (config.user) username;
  in {
    modules = builtins.attrValues {
      inherit
        (modules)
        ai
        amd
        cht
        dev
        doc
        efi
        gui
        hyp
        lap
        med
        off
        prn
        src
        vrt
        wif
        wrk
        ;
    };

    # ThinkPad P16s Gen 4 AMD (21QR001SUS, Ryzen AI 7 PRO 350). Pulls in
    # trackpoint support + the amd cpu/gpu and pc-laptop/ssd baselines.
    nixos.imports = [
      ./_hardware-configuration.nix
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p16s-amd-gen4
    ];
    users.${username} = {inherit (config) modules;};
  };
}
