{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    deploy.url = "github:serokell/deploy-rs";
    fix-python.url = "github:GuillaumeDesforges/fix-python";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nixvim.url = "github:malleum/nixvim";
    rip2.url = "github:MilesCranmer/rip2";
    stylix.url = "github:danth/stylix";
  };
  outputs = inputs: let
    system = "x86_64-linux";
    inherit (inputs.nixpkgs) lib;

    stable_overlay = final: _prev: {stable = import inputs.nix-stable {system = final.system;};};
    overlays = [stable_overlay];

    pkgs = import inputs.nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
    };

    ns = host: (lib.nixosSystem {
      specialArgs = {inherit pkgs inputs;};
      modules = [(./hosts + "/${host}")];
    });
  in {nixosConfigurations = lib.attrsets.genAttrs ["malleum" "magnus" "minimus"] ns;};
}
