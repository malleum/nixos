{inputs, ...}: {
  # services.fstrim.enable, from upstream.
  unify.modules.gui.nixos.imports = [
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];
}
