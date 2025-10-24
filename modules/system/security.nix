{
  unify.nixos = {
    security = {
      polkit.enable = true;
      sudo.wheelNeedsPassword = false;
    };
  };
}
