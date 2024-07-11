{
  lib,
  config,
  ...
}: {
  imports = [
    ./progs.nix
    ./servs.nix
    ./user.nix
  ];

  options.base = {
    enable = lib.mkEnableOption "Enables base.nix";
    servs.enable = lib.mkEnableOption "Enables services";
    progs.enable = lib.mkEnableOption "Enables programs";
    user.enable = lib.mkEnableOption "Enables user";
  };

  config = lib.mkIf config.base.enable {
    networking.networkmanager.enable = true;

    time.timeZone = "UTC";
    i18n.defaultLocale = "en_US.utf8";
    console.keyMap = "dvorak";

    nix.settings = {
      experimental-features = ["flakes" "nix-command"];
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

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
        cat = "bat";
        la = "ls -la";
        ls = "eza --icons";
        nixvim = "~/.config/nixvim/result/bin/nvim";
      };
    };
  };
}
