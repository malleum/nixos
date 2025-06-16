{
  inputs = {
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "unstable";

    determinix.url = "https://flakehub.com/f/DeterminateSystems/nix/*";
    fix-python.url = "github:GuillaumeDesforges/fix-python";
    hypr.url = "github:hyprwm/Hyprland";
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
    apps = forEachSystem (
      pkgs:
        lib.attrsets.genAttrs (map (a: builtins.substring 0 (builtins.stringLength (builtins.baseNameOf a) - 4) (builtins.baseNameOf a)) (lib.filesystem.listFilesRecursive ./modules/homemodules/scripts)) (name: {
          type = "app";
          program = "${pkgs.callPackage ./modules/homemodules/scripts/${name}.nix {inherit pkgs;}}/bin/${name}";
        })
    );
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
    homeConfigurations = let
      system = "aarch64-linux";
    in {
      "joshammer@mcspeed" = lib.homeManagerConfiguration {
        modules = [./hosts/minimus];
        extraSpecialArgs = {inherit inputs system;};
      };
    };
  };
}
