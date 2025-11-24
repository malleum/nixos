{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    nixvim = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
      inherit system;
      module = import ../../nixvim;
      extraSpecialArgs = {inherit pkgs inputs;};
    };

    nxvm = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
      inherit system;
      module = import ../../nxvm;
      extraSpecialArgs = {inherit pkgs inputs;
        plena = true;
      };
    };

    mvim = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
      inherit system;
      module = import ../../nxvm;
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
    packages.default = nxvm;

    apps.nvim = {
      type = "app";
      program = "${nxvm}/bin/nvim";
    };
    packages.nvim = nxvm;

    apps.mvim = {
      type = "app";
      program = "${mvim}/bin/nvim";
    };
    packages.mvim = mvim;
  };
}
