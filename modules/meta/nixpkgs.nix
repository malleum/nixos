{
  inputs,
  self,
  ...
}: let
  nixpkgs = {
    config.allowUnfree = true;

    overlays = [
      self.overlays.default
      (final: prev: {
        stable = import inputs.stable {
          system = prev.system;
          config.allowUnfree = true;
        };
      })
    ];
  };
in {
  imports = [inputs.flake-parts.flakeModules.easyOverlay];

  perSystem = {system, ...}: {
    imports = [
      "${inputs.unstable}/nixos/modules/misc/nixpkgs.nix"
      {inherit nixpkgs;}
    ];

    nixpkgs.hostPlatform = {inherit system;};
  };

  unify.nixos = {inherit nixpkgs;};
}
