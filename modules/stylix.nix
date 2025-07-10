{
  pkgs,
  inputs,
  ...
}: let
  image = ../wallpapers/grid.jpeg;
  convert = "${pkgs.imagemagick}/bin/magick";
  brightness = "-13";
  contrast = "0";
in {
  imports = [inputs.stylix.nixosModules.stylix];

  stylix = {
    enable = true;
    image = pkgs.runCommand "dimmed.jpg" {} ''${convert} ${image} -brightness-contrast ${brightness},${contrast} $out '';

    polarity = "dark";

    opacity = {
      terminal = 0.85;
      popups = 0.9;
    };
    cursor = {
      name = "graphite-light";
      package = pkgs.graphite-cursors;
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
}
