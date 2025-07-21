{
  inputs = {
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "unstable";
    };

    determinix.url = "https://flakehub.com/f/DeterminateSystems/nix/*";
    fix-python.url = "github:GuillaumeDesforges/fix-python";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "unstable";
    };

    nur.url = "github:nix-community/NUR";
    stylix.url = "github:danth/stylix";
    waywall.url = "github:malleum/waywall";
  };
  outputs = {self, ...} @ inputs: let
    inherit (inputs.unstable) lib;

    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs systems (
      system:
        import inputs.unstable {
          inherit system;
          config.allowUnfree = true;
        }
    );
    system = "x86_64-linux";
  in {
    devShells = forEachSystem (pkgs: {
      default = import ./shell.nix {inherit pkgs;};
      scripts = import ./modules/homemodules/shell.nix {inherit pkgs;};
    });
    apps.${system}.default = let
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
    nixosConfigurations = {
      "malleum" = lib.nixosSystem {
        specialArgs = {inherit inputs system;};
        modules = [./hosts/malleum];
      };
      "magnus" = lib.nixosSystem {
        specialArgs = {inherit inputs system;};
        modules = [./hosts/magnus];
      };
    };
  };
}
