{
  pkgs,
  name,
  ...
}: let
  dim = image: brightness:
    pkgs.runCommand "wallpaper.jpg" {}
    ''${pkgs.imagemagick}/bin/magick "${image}" -brightness-contrast ${brightness},0 $out '';
in {
  cybertruck = {
    base16Scheme = {
      base00 = "1a1b26"; # Main Background (bg)
      base01 = "16161e"; # Darker Background / Statusline (bg_dark)
      base02 = "292e42"; # Selection / Highlight Background (bg_highlight)
      base03 = "565f89"; # Comments (comment)
      base04 = "737aa2"; # Dark Foreground / UI Elements (dark5)
      base05 = "c0caf5"; # Main Foreground (fg)
      base06 = "a9b1d6"; # Secondary Foreground (fg_dark)
      base07 = "c0caf5"; # Lightest Foreground (fg - reused as max brightness)

      base08 = "f7768e"; # Red (red) - Variables, XML Tags, Diff Deleted
      base09 = "ff9e64"; # Orange (orange) - Integers, Boolean, Constants
      base0A = "e0af68"; # Yellow (yellow) - Classes, Search Text
      base0B = "9ece6a"; # Green (green) - Strings, Diff Inserted
      base0C = "7dcfff"; # Cyan (cyan) - Regex, Escape Characters
      base0D = "7aa2f7"; # Blue (blue) - Functions, Methods, Headings
      base0E = "bb9af7"; # Magenta (magenta) - Keywords, Storage, Diff Changed
      base0F = "1abc9c"; # Teal (teal) - Deprecated, Embedded Language Tags
    };
    image = dim (
      if name == "manus"
      then ./wallpapers/legotrain.png
      else ./wallpapers/legotesla.png
    ) "-20";
  };
}
