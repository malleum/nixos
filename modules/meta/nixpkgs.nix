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

      (final: prev: {
        pythonPackagesExtensions =
          prev.pythonPackagesExtensions
          ++ [
            (pyFinal: pyPrev: {
              # Asserts the old "must be str" TypeError wording, now "Expected
              # str, got int". Breaks piper-tts; drop once nixpkgs fixes it.
              pyopenjtalk-plus = pyPrev.pyopenjtalk-plus.overridePythonAttrs (old: {
                disabledTests =
                  (old.disabledTests or [])
                  ++ ["test_run_njd_from_mecab_invalid_input_should_not_break_next_call"];
              });
            })
          ];
      })
    ];
  };
in {
  imports = [inputs.flake-parts.flakeModules.easyOverlay];

  perSystem = {system, ...}: {
    imports = ["${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix" {inherit nixpkgs;}];

    nixpkgs.hostPlatform = {inherit system;};
  };

  flake.modules.nixos.base = {inherit nixpkgs;};
}
