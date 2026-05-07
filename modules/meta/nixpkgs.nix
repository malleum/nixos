{inputs, ...}: let
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

      # Skip flaky openldap test017-syncreplication-refresh (breaks bottles build)
      (final: prev: {
        openldap = prev.openldap.overrideAttrs (old: {
          doCheck = false;
        });
      })

      # Pin livekit to 1.9.12 — 1.10.0 causes immediate SIGNAL_SOURCE_CLOSE
      # on all clients; revert once upstream fixes the regression.
      (final: prev: {
        livekit = prev.livekit.overrideAttrs (_: {
          version = "1.9.12";
          src = prev.fetchFromGitHub {
            owner = "livekit";
            repo = "livekit";
            rev = "087050d18246fd22c8467d71fc1134f6d47485db";
            hash = "sha256-GVhhej3VZY/+UDs/TgRpe1nRMRNbJeAUvGv2GNrQGt4=";
          };
          vendorHash = "sha256-WzM1SzWvTeiygrt/TYjXXTG/LO2Wsp28Mf3PZMl0qmY=";
        });
      })
    ];
  };
in {
  imports = [inputs.flake-parts.flakeModules.easyOverlay];

  perSystem = {system, ...}: {
    imports = [
      "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix"
      {inherit nixpkgs;}
    ];

    nixpkgs.hostPlatform = {inherit system;};
  };

  unify.nixos = {inherit nixpkgs;};
}
