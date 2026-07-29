{inputs, ...}: {
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
    # Upstream baseline: microcode from enableRedistributableFirmware,
    # hardware.graphics on + 32-bit, amdgpu in initrd (early KMS), and
    # amd_pstate=active pinned rather than left to the kernel default.
    imports = with inputs.nixos-hardware.nixosModules; [
      common-cpu-amd-pstate # imports common-cpu-amd
      common-gpu-amd
    ];

    boot.kernelParams =
      [
        "amdgpu.gpu_recovery=1" # Enable GPU reset on hang instead of freezing the whole system
      ]
      ++ lib.optionals isApu [
        "amdgpu.sg_display=0" # Fix for scatter/gather display crashing on Cezanne APU under heavy memory load
        "amdgpu.noretry=0" # Help mitigate memory faults on APUs (do NOT enable on discrete GPUs)
      ];

    # Overrides common-gpu-amd's mkDefault ["modesetting"].
    services.xserver.videoDrivers = ["amdgpu"];

    users.users.${hostConfig.user.username}.extraGroups = ["render"];

    # ROCm compute, discrete GPU only. clr and clr.icd are ~878 MiB each and
    # do nothing useful on a Radeon 8xxM APU, so the laptops skip them.
    systemd.tmpfiles.rules = lib.optionals (!isApu) [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    hardware = {
      enableRedistributableFirmware = true;
      # graphics.enable / enable32Bit come from common-gpu-amd.
      graphics = {
        extraPackages = with pkgs;
          [
            mesa # radeonsi GL + radv Vulkan + VA-API driver
            libva-utils # vainfo for verifying VA-API
          ]
          ++ lib.optionals (!isApu) [rocmPackages.clr.icd];
        extraPackages32 = with pkgs; [
          driversi686Linux.mesa
          pkgsi686Linux.libva
        ];
      };
    };
  };
}
