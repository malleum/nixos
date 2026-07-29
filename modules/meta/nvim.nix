{inputs, ...}: {
  # Which nixvim a host gets. The full build carries the LSP servers,
  # formatters and linters -- including ltex-ls-plus, which drags in a JDK --
  # and measures 6.7 GiB of closure against mvim's 1.0. That is editor tooling,
  # so it follows the `dev` module rather than the hostname (which is what
  # picked it before, via a hardcoded check for "minimus").
  unify.nixos = {lib, ...}: {
    options.local.fullNvim = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use the full nixvim (LSP, linters, ltex) rather than mvim.";
    };
  };

  perSystem = {
    pkgs,
    system,
    ...
  }: let
    nixvim = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
      inherit system;
      module = {
        imports = [(import ../../nixvim)];
        nixpkgs.source = inputs.nixpkgs;
        version.enableNixpkgsReleaseCheck = false;
      };
      extraSpecialArgs = {
        inherit pkgs inputs;
        plena = true;
      };
    };

    mvim = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
      inherit system;
      module = {
        imports = [(import ../../nixvim)];
        nixpkgs.source = inputs.nixpkgs;
        version.enableNixpkgsReleaseCheck = false;
      };
      extraSpecialArgs = {
        inherit pkgs inputs;
        plena = false;
      };
    };
  in {
    apps.default = {
      type = "app";
      program = "${nixvim}/bin/nvim";
    };
    packages.default = nixvim;

    apps.nvim = {
      type = "app";
      program = "${nixvim}/bin/nvim";
    };
    packages.nvim = nixvim;

    apps.mvim = {
      type = "app";
      program = "${mvim}/bin/nvim";
    };
    packages.mvim = mvim;
  };
}
