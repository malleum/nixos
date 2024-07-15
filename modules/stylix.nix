{
  pkgs,
  inputs,
  ...
}: let
  image = /home/joshammer/OneDrive/Documents/Stuff/pics/car/cybertruckLego.jpg;
  # image = /home/joshammer/Downloads/gojo-hollow-purple-universe-jujutsu-kaisen-moewalls-com.mp4;
  real_image =
    if (builtins.substring ((builtins.stringLength image) - 4) 4 image) != ".mp4"
    then image
    else pkgs.runCommand "frame0.jpg" {} ''${ffmpeg} -i ${image} -vframes 1 $out'';

  ffmpeg = "${pkgs.ffmpeg}/bin/ffmpeg";
  convert = "${pkgs.imagemagick}/bin/magick";
  brightness = "-10";
  contrast = "0";
in {
  imports = [inputs.stylix.nixosModules.stylix];

  stylix = {
    enable = true;
    image = pkgs.runCommand "dimmed.jpg" {} ''${convert} ${real_image} -brightness-contrast ${brightness},${contrast} $out '';

    polarity = "dark";

    opacity = {
      terminal = 0.95;
      popups = 0.9;
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
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
    };

    targets = {
      nixvim.enable = false;
      fish.enable = false;
    };
  };
}
