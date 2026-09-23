{inputs, ...}: {
  unify.modules.dev.home = {
    lib,
    nixosConfig,
    pkgs,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;

    # ago, domain, rask and weave are flake inputs with no binary cache behind
    # them, so a `dev` host only gets them if it also took `src`
    # (modules/meta/source-builds.nix). Every host with `dev` takes `src` today;
    # this is what keeps that true for the next minimal one. iogii is a fetched
    # Ruby file behind a wrapper, nothing to compile, so it is unconditional.
    ownLanguages = [
      inputs.ago.packages.${system}.default
      inputs.domain.packages.${system}.default
      inputs.rask.packages.${system}.default
      inputs.weave.packages.${system}.default
    ];
    iogii = inputs.self.packages.${system}.iogii;
  in {
    home.packages =
      lib.optionals nixosConfig.local.buildFromSource ownLanguages
      ++ (with pkgs; [
        alejandra
        beamPackages.elixir
        clang-tools
        gcc
        gnumake
        go
        iogii
        jdk
        lua
        nodejs
        python3
        typst
      ]);
  };
}
