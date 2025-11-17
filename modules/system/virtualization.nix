{
  unify.nixos = {hostConfig, ...}: {
    boot.binfmt.emulatedSystems = ["aarch64-linux"]; # build arm packages

    users.users.${hostConfig.user.username}.extraGroups = [
      "kvm"
      "libvirtd"
    ];
  };
}
