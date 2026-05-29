{
  unify.modules.amd.nixos = {
    pkgs,
    lib,
    hostConfig,
    ...
  }: let
    # magnus is the only discrete-GPU host (RX 7700 XT / Navi32); the others are
    # APU laptops. The params below are APU workarounds that HARM a discrete GPU:
    # noretry=0 makes page faults retry instead of killing the faulting queue,
    # turning a single shader fault into a ring-timeout cascade -> full MODE1 GPU
    # reset -> VRAM loss -> Xwayland/desktop crash (observed under War Thunder).
    isApu = hostConfig.name != "magnus";
  in {
    boot.kernelParams =
      [
        "amdgpu.gpu_recovery=1" # Enable GPU reset on hang instead of freezing the whole system
      ]
      ++ lib.optionals isApu [
        "amdgpu.sg_display=0" # Fix for scatter/gather display crashing on Cezanne APU under heavy memory load
        "amdgpu.noretry=0" # Help mitigate memory faults on APUs (do NOT enable on discrete GPUs)
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
