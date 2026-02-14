{
  unify.nixos = {hostConfig, lib, ...}: {
    # Only emulate aarch64 on x86_64 hosts; minimus is native aarch64 and must not register it
    boot.binfmt.emulatedSystems = lib.mkIf (hostConfig.name != "minimus") ["aarch64-linux"];

    users.users.${hostConfig.user.username}.extraGroups = [
      "kvm"
      "libvirtd"
    ];
  };
}
