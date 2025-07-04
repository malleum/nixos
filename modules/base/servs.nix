{
  lib,
  config,
  ...
}: {
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
