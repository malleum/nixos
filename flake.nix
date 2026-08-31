{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    unify = {
      url = "git+https://codeberg.org/quasigod/unify.git";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        home-manager.follows = "home-manager";
      };
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Both default to their own pinned nixpkgs — fix-python's is from 2023-04
    # and would be evaluated and fetched in full alongside ours.
    fix-python = {
      url = "github:GuillaumeDesforges/fix-python";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Deliberately NOT following nixpkgs: Hyprland's cachix only has binaries
    # built against its own pin, and overriding it forces a local build.
    hypr.url = "github:hyprwm/Hyprland";
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    waywall = {
      url = "github:malleum/waywall";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    grapple = {
      url = "github:malleum/malleusite";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    iamb = {
      url = "github:malleum/iamb";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cls = {
      url = "github:malleum/cls";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ago = {
      url = "github:libertyluthermoffitt/ago/nunc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    domain = {
      url = "github:rfuller25/domainlang";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rask = {
      url = "github:malleum/rask";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    weave = {
      url = "github:malleum/weave";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mc = {
      url = "git+file:///home/joshammer/documents/gh/mc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jay = {
      url = "git+https://github.com/mahkoh/jay?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lerni = {
      url = "github:malleum/laering_norsk/esperanto-tool";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    termword = {
      url = "github:malleum/termword";
      inputs.nixpkgs.follows = "nixpkgs";
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
