{pkgs, ...}: let
  dim = image: brightness: pkgs.runCommand "wallpaper.jpg" {} ''${pkgs.imagemagick}/bin/magick "${image}" -brightness-contrast ${brightness},0 $out '';
in {
  space = {
    base16Scheme = {
      base00 = "001f26";
      base01 = "334e3b";
      base02 = "1e7a37";
      base03 = "999f9f";
      base04 = "97c0c6";
      base05 = "cecece";
      base06 = "c4d4d1";
      base07 = "b8d3dc";
      base08 = "53a364";
      base09 = "449caa";
      base0A = "84938e";
      base0B = "37a38c";
      base0C = "A34C51";
      base0D = "6996ab";
      base0E = "539d9c";
      base0F = "7c997a";
    };
    image = dim ./wallpapers/space.png "-10";
  };
  cybertruck = {
    base16Scheme = {
      base00 = "021d32";
      base01 = "36495a";
      base02 = "506d8b";
      base03 = "9f9bac";
      base04 = "acbac5";
      base05 = "dae3e8";
      base06 = "d6e3e9";
      base07 = "d7e1ea";
      base08 = "948d9f";
      base09 = "8990a2";
      base0A = "6694c5";
      base0B = "8292a2";
      base0C = "7794a6";
      base0D = "6696ba";
      base0E = "7896b0";
      base0F = "8393aa";
    };
    image = dim ./wallpapers/cybertruckLego.jpg "-20";
  };
}
