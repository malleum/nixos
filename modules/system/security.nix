{
  flake.modules.nixos.base = {
    security = {
      polkit.enable = true;
      sudo.wheelNeedsPassword = false;
    };
  };
}
