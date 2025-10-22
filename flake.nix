{
  inputs = {
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "unstable";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs.follows = "unstable";
    };

    unify = {
      url = "git+https://codeberg.org/quasigod/unify.git";
      inputs = {
        nixpkgs.follows = "unstable";
        flake-parts.follows = "flake-parts";
        home-manager.follows = "home-manager";
      };
    };

    nix-alien.url = "github:thiagokokada/nix-alien";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "unstable";
    };

    hypr.url = "github:hyprwm/Hyprland";
    stylix.url = "github:danth/stylix";
    waywall = {
      url = "github:malleum/waywall";
      inputs.nixpkgs.follows = "unstable";
    };
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (
      inputs.import-tree [
        ./hosts
        ./modules
      ]
    );
}
