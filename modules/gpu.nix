{
  pkgs,
  lib,
  config,
  ...
}: {
  options.gpu.enable = lib.mkEnableOption "Enables amdgpu";

  config = lib.mkIf config.gpu.enable {
    services.xserver.videoDrivers = ["amdgpu"];

    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          rocmPackages.clr.icd
          mesa # Mesa drivers including radv (open-source Vulkan)
        ];
        extraPackages32 = with pkgs; [
          driversi686Linux.mesa # 32-bit support for Steam games
          pkgsi686Linux.libva
        ];
      };
    };
  };
}
