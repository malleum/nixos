{
  pkgs,
  inputs,
  lib,
  ...
}: let
  themes = import ./themes.nix {inherit pkgs;};
  mkStylixTheme = theme: {
    stylix = {
      image = lib.mkForce themes.${theme}.image;
      base16Scheme = lib.mkForce themes.${theme}.base16Scheme;
    };
  };
  theme = "space";
in {
  imports = [inputs.stylix.nixosModules.stylix];

  stylix = {
    enable = true;
    image = themes.${theme}.image;
    base16Scheme = themes.${theme}.base16Scheme;

    polarity = "dark";

    opacity = {
      terminal = 0.85;
      popups = 0.9;
    };
    cursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 32;
    };

    fonts = {
      sizes = {
        terminal = 13;
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "NotoSans";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "NotoSerif";
      };
    };

    targets = {
      fish.enable = false;
      nixvim.enable = false;
    };
  };
  specialisation = builtins.mapAttrs (name: _: {configuration = {imports = [(mkStylixTheme name)];};}) themes;
}
