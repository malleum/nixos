{self, ...}: {
  systems = ["x86_64-linux" "aarch64-linux"];
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
