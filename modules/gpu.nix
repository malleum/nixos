{
  pkgs,
  lib,
  config,
  ...
}: {
  options.gpu.enable = lib.mkEnableOption "Enables amdgpu";

  config = lib.mkIf config.gpu.enable {
    services.xserver.videoDrivers = ["amdgpu" "nvidia"];

    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    hardware = {
      graphics.extraPackages = with pkgs; [rocmPackages.clr.icd];
    };
  };
}
