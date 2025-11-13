{self, ...}: {
  perSystem = {lib, ...}: {
    apps.default = let
      nixvimPackage =
        lib.findFirst
        (pkg: pkg.name == "nixvim")
        null
        self.nixosConfigurations.malleum.config.environment.systemPackages;
    in
      assert nixvimPackage != null; {
        type = "app";
        program = "${nixvimPackage}/bin/nvim";
      };
  };
}
