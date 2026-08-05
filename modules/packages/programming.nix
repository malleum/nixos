{inputs, ...}: {
  # The toolchain host also gets the full editor.
  unify.modules.dev.nixos.local.fullNvim = true;

  unify.modules.dev.home = {pkgs, ...}: let
    ago = inputs.ago.packages.${pkgs.stdenv.hostPlatform.system}.default;
    domain = inputs.domain.packages.${pkgs.stdenv.hostPlatform.system}.default;
    iogii = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.iogii;
    rask = inputs.rask.packages.${pkgs.stdenv.hostPlatform.system}.default;
    weave = inputs.weave.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    home.packages = with pkgs; [
      ago
      alejandra
      clang-tools
      domain
      gcc
      gnumake
      go
      iogii
      jdk
      lua
      nodejs
      python3
      rask
      typst
      weave
    ];
  };
}
