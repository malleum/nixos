{inputs, ...}: {
  unify.nixos = {config, ...}: let
    allowed-users = ["@wheel"];
  in {
    sops.templates.nix-access-tokens = {
      content = "access-tokens = github.com=${config.sops.placeholder.github_token}";
      owner = "root";
      group = "wheel";
      mode = "0440";
    };

    nix = {
      # This makes 'nix shell nixpkgs#...' use the same nixpkgs as your system
      registry.nixpkgs.flake = inputs.nixpkgs;
      # This makes legacy commands like 'nix-shell -p' use the same nixpkgs
      nixPath = ["nixpkgs=${inputs.nixpkgs}"];

      extraOptions = ''
        !include ${config.sops.templates.nix-access-tokens.path}
      '';

      # Hardlink duplicate store paths weekly instead of hashing every path
      # inline during every build (what auto-optimise-store did).
      optimise = {
        automatic = true;
        dates = ["weekly"];
      };

      settings = {
        inherit allowed-users;
        trusted-users = allowed-users;

        # Deliberately NOT auto-optimise-store: that hashes every path inline
        # on every build. nix.optimise below does the same dedupe on a timer.

        experimental-features = [
          "flakes"
          "nix-command"
        ];
        # cache.nixos.org and its key are already NixOS defaults; listing them
        # again just produced a duplicate entry in nix.conf's substituters.
        substituters = [
          "https://hyprland.cachix.org"
        ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };
    };
  };
}
