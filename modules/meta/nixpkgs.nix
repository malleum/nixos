{
  inputs,
  self,
  ...
}: let
  nixpkgs = {
    config.allowUnfree = true;

    overlays = [
      self.overlays.default # TODO: what does this mean?
      (final: prev: {
        stable = import inputs.stable {
          system = prev.system;
          config.allowUnfree = true;
        };
      })
    ];
  };
in {
  imports = [inputs.flake-parts.flakeModules.easyOverlay]; # TODO: what does this mean?

  perSystem = {system, ...}: { # TODO: what does this mean?
    imports = ["${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix" {inherit nixpkgs;}];

    nixpkgs.hostPlatform = {inherit system;};
  };

  unify.nixos = {inherit nixpkgs;};
}
