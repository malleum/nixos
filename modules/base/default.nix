{
  inputs,
  lib,
  config,
  system,
  ...
}: {
  imports = [
    ./progs.nix
    ./servs.nix
    ./user.nix
  ];

  options = {
    wm = lib.mkOption {default = "";};
    base = {
      enable = lib.mkEnableOption "Enables base.nix";
      servs.enable = lib.mkEnableOption "Enables services";
      progs.enable = lib.mkEnableOption "Enables programs";
      user.enable = lib.mkEnableOption "Enables user";
    };
  };

  config = lib.mkIf config.base.enable {
    networking.networkmanager.enable = true;

    time.timeZone = "America/New_York";
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "dvorak";

    nix = {
      package = lib.mkForce inputs.determinix.packages.${system}.default;
      settings = {
        auto-optimise-store = true;
        experimental-features = ["flakes" "nix-command"];
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

    nixpkgs.pkgs = let
      overlays = [
        inputs.nur.overlays.default
        (final: prev: {
          stable = import inputs.stable {
            system = prev.system;
            config.allowUnfree = true;
          };
        })
      ];

      pkgs = import inputs.unstable {
        inherit overlays system;
        config.allowUnfree = true;
      };
    in
      pkgs;

    system = {
      stateVersion = "22.11"; # DON'T CHANGE THIS
      autoUpgrade.enable = true;
    };

    environment = {
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        BROWSER = "brave";
        TERMINAL = "foot";
      };

      shellAliases = {
        sp = "spotify_player";
      };
    };
  };
}
