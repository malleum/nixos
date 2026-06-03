{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    cls = inputs.cls.packages.${pkgs.stdenv.hostPlatform.system}.default;

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

    apps.cls = {
      type = "app";
      program = "${cls}/bin/cls";
    };
    packages.cls = cls;
  };
}
