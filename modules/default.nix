{
  lib,
  config,
  ...
}: {
  imports = [
    ./base
    ./battery.nix
    ./boot.nix
    ./gpu.nix
    ./hypr
    ./i3
    ./loginmanagers
    ./packages
    ./stylix.nix
  ];

  options.omni.enable = lib.mkOption {default = true;};

  config = lib.mkIf config.omni.enable {
    base = {
      enable = lib.mkDefault true;
      servs.enable = lib.mkDefault true;
      progs.enable = lib.mkDefault true;
      user.enable = lib.mkDefault true;
    };

    home.enable = lib.mkDefault true;
    hypr.enable = lib.mkDefault true;
    i3.enable = lib.mkDefault true;

    packages = {
      enable = lib.mkDefault true;
      gui.enable = lib.mkDefault true;
      minimus.enable = lib.mkDefault true;
      programming.enable = lib.mkDefault true;
      etc.enable = lib.mkDefault true;
    };
    sddm.enable = lib.mkDefault false;
  };
}
