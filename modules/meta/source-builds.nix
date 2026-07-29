# Opt-in source builds.
#
# jay and iamb both exist in nixpkgs as cached binaries, and both also have
# flake inputs pointing at forks/tips that have to be compiled locally. A fresh
# laptop should not need a Rust toolchain and an hour of CPU just to get a
# desktop, so the modules that consume them use plain `pkgs.jay` / `pkgs.iamb`
# and this module swaps in the source builds for hosts that ask for it.
#
# Add `src` to a host's module list to get the from-source versions. Leave it
# off (the bootstrap template does) and the host installs prebuilt from the
# binary cache.
{inputs, ...}: {
  unify.modules.src.nixos = {pkgs, ...}: let
    inherit (pkgs.stdenv.hostPlatform) system;
  in {
    nixpkgs.overlays = [
      (_final: _prev: {
        jay = inputs.jay.packages.${system}.jay;
        iamb = inputs.iamb.packages.${system}.default;
      })
    ];
  };
}
