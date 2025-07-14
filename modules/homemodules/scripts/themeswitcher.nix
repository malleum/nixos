{
  pkgs,
  lib,
  ...
}: let
  # Import your themes file. Adjust the path if necessary.
  themes = import ../../stylix/themes.nix {inherit pkgs;};

  # 1. Generate the input for Rofi.
  #    This creates a multi-line string where each line is:
  #    theme_name\0icon\x1f/path/to/wallpaper
  rofi-input = lib.concatMapStringsSep "\n" (
    name: "${name}\0icon\x1f${themes.${name}.image}"
  ) (lib.attrNames themes);
  # 2. Write the shell script using the generated input.
in
  pkgs.writers.writeFishBin "themeswitcher" {}
  # fish
  ''
    # Use `echo -e` to correctly interpret the special characters for Rofi
    set selected_theme (echo -e "${rofi-input}" | rofi -dmenu -i -p "theme")

    # If the user selected a theme (and didn't just press escape),
    # then run the theme command with the selection.
    if [[ -n "$selected_theme" ]]; then
      theme "$selected_theme"
    fi
  ''
