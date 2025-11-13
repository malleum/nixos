{
  self,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    nixvimConfig = {
      imports = [
        self.nixosModules.nixvim
        inputs.nixvim.nixosModules.nixvim
      ];
    };
    nixvimPackage = inputs.nixvim.lib.${system}.nixvim-build {
      inherit pkgs;
      module = nixvimConfig;
    };
  in {
    apps.default = {
      type = "app";
      program = "${nixvimPackage}/bin/nvim";
    };
    packages.default = nixvimPackage;
  };
}

