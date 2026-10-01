{
  flake.modules.nixos.efi = {
    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
      timeout = 10;
    };
  };
}
