{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    nixvim' = inputs.nixvim.legacyPackages.${system};
    nixvimModule = {
      inherit system;
      module = import ../../nixvim;
      extraSpecialArgs = {
        inherit pkgs system;
      };
    };
    nixvimPackage = nixvim'.makeNixvimWithModule nixvimModule;
  in {
    apps.default = {
      type = "app";
      program = "${nixvimPackage}/bin/nvim";
    };
    packages.default = nixvimPackage;
  };
}
