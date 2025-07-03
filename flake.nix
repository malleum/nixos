{
  inputs = {
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "unstable";

    determinix.url = "https://flakehub.com/f/DeterminateSystems/nix/*";
    fix-python.url = "github:GuillaumeDesforges/fix-python";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nixvim.url = "github:malleum/nixvim";
    nur.url = "github:nix-community/NUR";
    stylix.url = "github:danth/stylix";
  };
  outputs = inputs: let
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
  in {
    devShells = forEachSystem (pkgs: {
      default = import ./shell.nix {inherit pkgs;};
      scripts = import ./modules/homemodules/shell.nix {inherit pkgs;};
    });
    nixosConfigurations = let
      system = "x86_64-linux";
    in {
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
