{pkgs, ...}: let
  dim = image: brightness: pkgs.runCommand "wallpaper.jpg" {} ''${pkgs.imagemagick}/bin/magick "${image}" -brightness-contrast ${brightness},0 $out '';
in {
  # space = {
  #   base16Scheme = {
  #     base00 = "001f26";
  #     base01 = "334e3b";
  #     base02 = "1e7a37";
  #     base03 = "999f9f";
  #     base04 = "97c0c6";
  #     base05 = "cecece";
  #     base06 = "c4d4d1";
  #     base07 = "b8d3dc";
  #     base08 = "53a364";
  #     base09 = "449caa";
  #     base0A = "84938e";
  #     base0B = "37a38c";
  #     base0C = "A34C51";
  #     base0D = "6996ab";
  #     base0E = "539d9c";
  #     base0F = "7c997a";
  #   };
  #   image = dim ./wallpapers/space.png "-10";
  # };
  cybertruck = {
    base16Scheme = {
      base00 = "12151a"; # Deep, cool black from the background shadows
      base01 = "21262e"; # Dark grey from the surface
      base02 = "3a424d"; # Muted grey from the floor texture
      base03 = "6c7a8b"; # Softer grey for comments
      base04 = "a1a9b3"; # Main color of the LEGO brick's shadow
      base05 = "c5cbd3"; # Main color of the LEGO brick
      base06 = "dfe4e9"; # Highlight color on the brick
      base07 = "f0f3f5"; # Brightest highlight from the light reflection

      base08 = "d18da4"; # Muted Rose (for Red) from subtle ambient light
      base09 = "a8968e"; # Desaturated Taupe (for Orange) from the surface
      base0A = "82a4b0"; # Slate Blue (for Yellow) from the lower haze
      base0B = "74b3c4"; # Muted Teal (for Green) from the lower haze
      base0C = "88c0d0"; # Icy Blue (for Cyan) from reflections
      base0D = "5e9de5"; # Bright Blue (for Blue) from the lens flare
      base0E = "a396c4"; # Muted Lavender (for Magenta) from the shadows
      base0F = "8d827e"; # Desaturated Brown (for Brown) from floor texture    };
    };
    image = dim ./wallpapers/legotesla.png "-20";
  };
}
