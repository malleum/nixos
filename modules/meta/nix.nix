{
  unify.nixos = {config, ...}: let
    allowed-users = ["@wheel"];
  in {
    sops.templates.nix-access-tokens = {
      content = "access-tokens = github.com=${config.sops.placeholder.github_token}";
      owner = "root";
      group = "wheel";
      mode = "0440";
    };

    nix.extraOptions = ''
      !include ${config.sops.templates.nix-access-tokens.path}
    '';

    nix.settings = {
      inherit allowed-users;
      trusted-users = allowed-users;

      auto-optimise-store = true;

      experimental-features = [
        "flakes"
        "nix-command"
      ];
      substituters = [
        "https://cache.nixos.org/"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };
}
