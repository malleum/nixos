# Opt-in source builds.
#
# Some of what this config installs has no binary cache behind it: flake inputs
# pointing at forks and tips, and derivations built here from a pinned git rev.
# A fresh laptop should not need a Rust toolchain and an hour of CPU just to get
# a desktop, so anything that has to be compiled locally is collected here (or
# gated on `local.buildFromSource`, for the cases that are entangled with other
# config) and only lands on hosts that ask for it.
#
# Two kinds live behind this switch:
#
#   * jay and iamb exist in nixpkgs as cached binaries, and the modules that
#     consume them use plain `pkgs.jay` / `pkgs.iamb`. The overlay below swaps
#     in the from-source versions.
#   * cls, lerni, termword and wl-tray-bridge have no cached version at all, so
#     for a host without `src` they are simply absent.
#
# Add `src` to a host's module list to get all of it. Leave it off (minoris and
# the bootstrap template do) and the host installs nothing that is not already
# in the binary cache.
{inputs, ...}: {
  # Read by modules that build from source as a side effect of other config,
  # where moving the package here would mean moving the config with it --
  # currently jay's wl-tray-bridge.
  unify.nixos = {lib, ...}: {
    options.local.buildFromSource = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Host is willing to compile packages that have no binary cache.";
    };
  };

  unify.modules.src.nixos = {pkgs, ...}: let
    inherit (pkgs.stdenv.hostPlatform) system;
  in {
    local.buildFromSource = true;

    nixpkgs.overlays = [
      (_final: _prev: {
        jay = inputs.jay.packages.${system}.jay;
        iamb = inputs.iamb.packages.${system}.default;
      })
    ];
  };

  # The uncached packages that are nothing but a package: no config to keep
  # them company, so they sit here rather than behind a conditional in the
  # module that used to own them.
  #
  #   cls      -- was in modules/packages/cli.nix
  #   lerni    -- was in modules/packages/more_cli.nix
  #   termword -- likewise
  unify.modules.src.home = {pkgs, ...}: let
    inherit (pkgs.stdenv.hostPlatform) system;
  in {
    home.packages = [
      inputs.cls.packages.${system}.default
      inputs.lerni.packages.${system}.default
      inputs.termword.packages.${system}.default
    ];
  };
}
