{
  lib,
  config,
  ...
}: let
  cnh = config.networking.hostName;
  mkIfElse = {
    _if,
    _then,
    _else,
  }:
    lib.mkMerge [
      (lib.mkIf _if _then)
      (lib.mkIf (!_if) _else)
    ];
in {
  options.booting.opt = lib.mkOption {default = "";};

  config = mkIfElse {
    _if = (config.booting.opt == "" && cnh != "magnus") || config.booting.opt == "efi";
    _then = {
      boot.loader = {
        systemd-boot.enable = true;
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot/efi";
        };
      };
    };
    _else = {
      boot.loader.grub = {
        enable = true;
        device = "/dev/nvme0n1";
        useOSProber = true;
      };
    };
  };
}
