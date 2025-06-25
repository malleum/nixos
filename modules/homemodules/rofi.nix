{
  pkgs,
  config,
  ...
}: {
  stylix.targets.rofi.enable = false;
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    location = "center";
    terminal = "kitty";
    plugins = with pkgs; [rofi-emoji-wayland (rofi-calc.override {rofi-unwrapped = pkgs.rofi-wayland-unwrapped;})];
    extraConfig = {
      kb-primary-paste = "Control+V,Shift+Insert";
      drun-display-format = "{icon} {name}";
      show-icons = true;
      hide-scrollbar = true;
      display-drun = " 󰀘 =>  ";
      display-calc = " ⅀ =>  ";
      display-emoji = " 🫠 =>  ";
    };
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
      # Inherit base colors from your stylix configuration
      b0 = "#${config.stylix.base16Scheme.base00}";
      b1 = "#${config.stylix.base16Scheme.base01}";
      b2 = "#${config.stylix.base16Scheme.base02}";
      b5 = "#${config.stylix.base16Scheme.base05}"; # Main foreground/text color
      b9 = "#${config.stylix.base16Scheme.base09}"; # A nice accent color
      bc = "#${config.stylix.base16Scheme.base0C}"; # Another accent for selected text

      # --- Modern Additions ---
      bg-main = "${b0}CC";
      bg-alt = "${b1}33";
      bg-selected = "${b9}4D";
      transparent = "#00000000";
    in {
      "*" = {
        background-color = mkLiteral transparent;
        text-color = mkLiteral b5;
      };

      "window" = {
        location = mkLiteral "center";
        anchor = mkLiteral "center";
        width = mkLiteral "45%";
        height = mkLiteral "50%";
        padding = mkLiteral "24px";
        border = mkLiteral "2px";
        border-radius = mkLiteral "16px";
        border-color = mkLiteral b9;
        background-color = mkLiteral bg-main;
      };

      "mainbox" = {
        orientation = mkLiteral "vertical";
        children = mkLiteral "[inputbar, listview]";
        spacing = mkLiteral "16px";
        background-color = mkLiteral transparent;
      };

      "inputbar" = {
        children = mkLiteral "[prompt, entry]";
        spacing = mkLiteral "12px";
        padding = mkLiteral "12px";
        border-radius = mkLiteral "12px";
        background-color = mkLiteral bg-alt;
      };

      "prompt" = {
        enabled = true;
        text-color = mkLiteral b9;
        background-color = mkLiteral transparent;
      };

      "entry" = {
        placeholder = "Search applications...";
        placeholder-color = mkLiteral b2;
        text-color = mkLiteral bc;
        cursor = mkLiteral "text";
        background-color = mkLiteral transparent;
      };

      "listview" = {
        # This is the stable, compatible way to create a grid.
        # It uses the default vertical layout with multiple columns.
        columns = 6;
        lines = 3;
        spacing = mkLiteral "12px";
        cycle = true;
        background-color = mkLiteral transparent;
      };

      "element" = {
        orientation = mkLiteral "vertical";
        cursor = mkLiteral "pointer";
        spacing = mkLiteral "8px";
        padding = mkLiteral "12px";
        border-radius = mkLiteral "12px";
      };

      "element-icon" = {
        size = mkLiteral "3.5em";
        horizontal-align = mkLiteral "0.5";
        background-color = mkLiteral transparent;
      };

      "element-text" = {
        horizontal-align = mkLiteral "0.5";
        text-color = mkLiteral "inherit";
        background-color = mkLiteral transparent;
      };

      "element selected" = {
        background-color = mkLiteral bg-selected;
        text-color = mkLiteral bc;
      };
    };
  };
}
