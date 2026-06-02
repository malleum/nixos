{
  unify.modules.dbt.nixos = {
    boot.loader.systemd-boot = {
      edk2-uefi-shell.enable = true;
      windows."11".efiDeviceHandle = "HD1b";
    };
  };
}
