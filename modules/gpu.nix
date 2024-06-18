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

    hardware.opengl.extraPackages = with pkgs; [rocmPackages.clr.icd];
  };
}
