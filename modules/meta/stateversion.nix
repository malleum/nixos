let
  stateVersion = "23.11";
in {
  unify = {
    home.home = {inherit stateVersion;};
    nixos.system = {inherit stateVersion;};
  };
}
