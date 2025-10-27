{
  unify.nixos = {config, ...}: {
    boot.binfmt.emulatedSystems = ["aarch64-linux"]; # build arm packages

    users.users.${config.user.username}.extraGroups = ["kvm" "libvirtd"];
  };
}
