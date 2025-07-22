{
  lib,
  config,
  ...
}: {
  imports = [./keyboard.nix];

  config = lib.mkIf config.base.servs.enable {
    # Faster boot (may help overall responsiveness)
    systemd.extraConfig = ''
      DefaultTimeoutStopSec=10s
    '';

    services = {
      # If using SSD
      fstrim.enable = true;

      printing.enable = true;
      openssh.enable = true;
      flatpak.enable = true;
      resolved.enable = true;

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };

      xserver = {
        enable = true;
        xkb.extraLayouts = {
          mcsr = {
            description = "MCSR Custom Layout";
            languages = ["eng"];
            symbolsFile = builtins.toFile "mcsrkeyboard.xkb" config.keyboard;
          };
        };
      };
    };

    security = {
      rtkit.enable = true;
      polkit.enable = true;
      sudo.wheelNeedsPassword = false;
    };

    hardware = {
      bluetooth.enable = true;
      acpilight.enable = true;
    };
    boot.binfmt.emulatedSystems = ["aarch64-linux"]; # build arm packages
  };
}
