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

    nvf =
      (inputs.nvf.lib.neovimConfiguration {
        inherit pkgs;
        modules = [(import ../../nvf {inherit inputs pkgs;})];
      }).neovim;
  in {
    apps.default = {
      type = "app";
      program = "${nvf}/bin/nvim";
    };
    packages.default = nvf;

    apps.nvim = {
      type = "app";
      program = "${nixvim}/bin/nvim";
    };
    packages.nvim = nixvim;
  };
}
