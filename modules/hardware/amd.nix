{
  unify.modules.amd.nixos = {
    pkgs,
    hostConfig,
    ...
  }: {
    boot.kernelParams = [
      "amdgpu.gpu_recovery=1" # Enable GPU reset on hang instead of freezing the whole system
      "amdgpu.ppfeaturemask=0xfffd7fff" # Disable SDMA power gating (bit 15) to prevent sdma0 hangs
    ];

    services.xserver.videoDrivers = ["amdgpu"];

    users.users.${hostConfig.user.username}.extraGroups = ["render"];

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
