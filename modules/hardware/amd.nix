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
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    hardware = {
      enableRedistributableFirmware = true;
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          rocmPackages.clr.icd
          mesa # radeonsi GL + radv Vulkan + VA-API driver
          libva-utils # vainfo for verifying VA-API
        ];
        extraPackages32 = with pkgs; [
          driversi686Linux.mesa
          pkgsi686Linux.libva
        ];
      };
    };
  };
}
