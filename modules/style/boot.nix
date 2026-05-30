{
  unify.modules.gui.nixos = {lib, ...}: {
    stylix.targets.plymouth.enable = lib.mkForce false;
    boot.plymouth.enable = lib.mkForce false;
  };
}
