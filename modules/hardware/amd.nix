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

    # Render-node numbering is not stable across boots on magnus: the dGPU is
    # four bridges deep (00:01.1 -> 01:00.0 -> 02:00.0 -> 03:00.0) while the
    # Raphael iGPU is direct (00:08.1 -> 0f:00.0), so whichever probes first
    # takes renderD128. All the display outputs are on the dGPU, so on boots
    # where the iGPU wins the race every Mesa client that just takes the first
    # render node renders on the iGPU and copies each frame back over PCIe.
    # Measured on such a boot: Minecraft 180 -> 120 fps, iGPU pinned at 100%
    # and 45 W (stealing package power from the cores) while the dGPU sat at
    # 1378 of 2226 MHz. DRI_PRIME matches the pci- tag against the device
    # address, so it picks the right GPU whatever order the nodes come up in.
    environment.sessionVariables = lib.optionalAttrs (!isApu) {
      DRI_PRIME = "pci-0000_03_00_0";
    };

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
