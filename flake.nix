{
  description = "based nixos flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-stable.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-alien.url = "github:thiagokokada/nix-alien";
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    nixvim.url = "github:speedster33/nixvim";
    stylix.url = "github:danth/stylix";
    fix-python.url = "github:GuillaumeDesforges/fix-python";
  };
  outputs = inputs: let
    system = "x86_64-linux";

    stable_overlay = final: _prev: {stable = import inputs.nix-stable {system = final.system;};};
    overlays = [stable_overlay];

    pkgs = import inputs.nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
    };

    inherit (inputs.nixpkgs) lib;

    ns = host: (lib.nixosSystem {
      specialArgs = {inherit pkgs inputs;};
      modules = [(./hosts + "/${host}")];
    });
  in {nixosConfigurations = lib.attrsets.genAttrs ["malleum" "magnus" "minimus"] ns;};
}
