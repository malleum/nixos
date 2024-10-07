{
  pkgs,
  inputs,
  ...
}: let
  image = /home/joshammer/.config/nixos/wallpapers/dark_sky_su57.jpg;
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
      terminal = 0.7;
      popups = 0.9;
    };
    cursor = {
      name = "material_light_cursors";
      package = pkgs.material-cursors;
      size = 32;
    };

    fonts = {
      sizes = {
        terminal = 13;
      };
      monospace = {
        package = pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];};
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

    targets = {fish.enable = false;};
  };
}
