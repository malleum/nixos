{
  unify.modules.amd.nixos = {
    pkgs,
    hostConfig,
    ...
  }: {
    boot.kernelParams = [
      "amdgpu.gpu_recovery=1" # Enable GPU reset on hang instead of freezing the whole system
      "amdgpu.sg_display=0" # Fix for scatter/gather display crashing on Cezanne APU under heavy memory load
      "amdgpu.noretry=0" # Help mitigate memory faults on APUs
    ];

    services.xserver.videoDrivers = ["amdgpu"];

    users.users.${hostConfig.user.username}.extraGroups = ["render"];

    # Re-enable for discrete AMD GPU (ROCm compute):
    # systemd.tmpfiles.rules = [
    #   "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    # ];

    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          # rocmPackages.clr.icd # Re-enable for discrete AMD GPU (ROCm compute)
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
