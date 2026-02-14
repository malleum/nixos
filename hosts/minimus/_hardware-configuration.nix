{
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];

  boot.initrd.availableKernelModules = ["xhci_pci" "virtio_scsi"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0f34aeb0-4da7-4e73-9081-9b5773aea870";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0CF4-0388";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  swapDevices = [];

  # Static networking is in _network.nix
  networking.useDHCP = false;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # Native aarch64: do not register binfmt for aarch64 (avoids assertion in binfmt.nix)
  boot.binfmt.emulatedSystems = lib.mkForce [];
}
