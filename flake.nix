{
  inputs = {
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "unstable";

    hypr.url = "github:hyprwm/Hyprland";
    fix-python.url = "github:GuillaumeDesforges/fix-python";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nixvim.url = "github:malleum/nixvim";
    stylix.url = "github:danth/stylix";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs:
    inputs.flake-utils.lib.eachSystem inputs.flake-utils.lib.allSystems (
      system: let
        inherit (inputs.unstable) lib;

        ns = host: (lib.nixosSystem {
          specialArgs = {inherit inputs system;};
          modules = [(./hosts + "/${host}")];
        });

        pkgs = import inputs.unstable {inherit system;};
        ss = name: {
          type = "app";
          program = "${pkgs.callPackage ./modules/homemodules/scripts/${name}.nix {inherit pkgs;}}/bin/${name}";
        };
      in {
        apps.${system} = lib.attrsets.genAttrs (map (a: builtins.substring 0 (builtins.stringLength (builtins.baseNameOf a) - 4) (builtins.baseNameOf a)) (lib.filesystem.listFilesRecursive ./modules/homemodules/scripts)) ss;
        devShells.${system} = {
          default = import ./shell.nix {inherit pkgs;};
          scripts = import ./modules/homemodules/shell.nix {inherit pkgs;};
        };
        nixosConfigurations = lib.attrsets.genAttrs ["malleum" "magnus"] ns;
        homeConfigurations = {
          "joshammer@minimus" = lib.homeManagerConfiguration {
            modules = [./hosts/minimus];
            extraSpecialArgs = {inherit inputs system;};
          };
        };
      }
    );
}
