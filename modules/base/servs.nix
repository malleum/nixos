{
  lib,
  config,
  inputs,
  ...
}: {
  # imports = [inputs.xremap.nixosModules.default];

  config = lib.mkIf config.base.servs.enable {
    services = {
      unclutter.enable = true;
      printing.enable = true;
      openssh.enable = true;

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };

      # xremap = {
      #   withHypr = true;
      #   serviceMode = "user";
      #   userName = "joshammer";
      #   yamlConfig = ''
      #     modmap:
      #       - name: capsesc
      #         window:
      #           not: [aces.exe]
      #         remap:
      #           CAPSLOCK: Esc
      #   '';
      # };
      #
    };

    security = {
      rtkit.enable = true;
      polkit.enable = true;
    };

    hardware = {
      bluetooth.enable = true;
      acpilight.enable = true;
      pulseaudio.enable = false;
    };
    boot.binfmt.emulatedSystems = ["aarch64-linux"]; # build arm packages
  };
}
