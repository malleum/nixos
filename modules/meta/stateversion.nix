let
  stateVersion = "26.05";
in {
  flake.modules = {
    homeManager.base.home = {inherit stateVersion;};
    nixos.base.system = {inherit stateVersion;};
  };
}
