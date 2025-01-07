{
  inputs = {
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "unstable";
    flake-utils.url = "github:numtide/flake-utils";

    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    base16.url = "github:SenchoPens/base16.nix/665b3c6748534eb766c777298721cece9453fdae";
    deploy.url = "github:serokell/deploy-rs";
    hypr.url = "github:hyprwm/Hyprland";
    hyprqt.url = "github:hyprwm/hyprland-qtutils";
    fix-python.url = "github:GuillaumeDesforges/fix-python";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nixvim.url = "github:malleum/nixvim";
    nxvim.url = "github:nix-community/nixvim";
    rip2.url = "github:MilesCranmer/rip2";
    stylix.url = "github:danth/stylix";
    stylix.inputs.base16.follows = "base16";
  };
  outputs = inputs: let
    system = "x86_64-linux";
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
    nixosConfigurations = lib.attrsets.genAttrs ["malleum" "magnus" "minimus"] ns;
  };
}
