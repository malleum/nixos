{inputs, ...}: {
  # services.fstrim.enable, from upstream.
  flake.modules.nixos.gui.imports = [
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];
}
