{ inputs, ... }:
let
  nixpkgs = {
    config.allowUnfree = true;

    overlays = [
      inputs.nur.overlays.default

      (final: prev: {
        stable = import inputs.stable {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      })
    ];
  };
in
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];

  perSystem =
    { system, ... }:
    {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix"
        { inherit nixpkgs; }
      ];

      nixpkgs.hostPlatform = { inherit system; };
    };

  unify.nixos = { inherit nixpkgs; };
}
