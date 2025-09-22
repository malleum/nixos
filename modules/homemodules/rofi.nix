{
  pkgs,
  config,
  ...
}: {
  config = {
    stylix.targets.rofi.enable = false;
    programs.rofi = let
      # This is the correct way to access the home-manager helper function.
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      enable = true;
      package = pkgs.rofi;
      terminal = "foot";
      location = "center";
      plugins = with pkgs; [rofi-emoji rofi-calc];

      extraConfig = {
        kb-primary-paste = "Control+V,Shift+Insert";
        drun-display-format = "{icon} {name}";
        show-icons = true;
        hide-scrollbar = true;
        display-drun = " 󰀘 =>  ";
        display-calc = " ⅀ =>  ";
        display-emoji = " 🫠 =>  ";
      };

      # A single, unified theme definition.
      theme = {
        "*" = {
          background-color = mkLiteral "#00000000";
          text-color = mkLiteral "#${config.stylix.base16Scheme.base05}";
        };
        "window" = {
          location = mkLiteral "center";
          anchor = mkLiteral "center";
          width = mkLiteral "50%";
          height = mkLiteral "50%";
          padding = mkLiteral "24px";
          border = mkLiteral "2px";
          border-radius = mkLiteral "16px";
          border-color = mkLiteral "#${config.stylix.base16Scheme.base09}";
          background-color = mkLiteral "#${config.stylix.base16Scheme.base00}CC";
        };
        "mainbox" = {
          orientation = mkLiteral "vertical";
          # IMPORTANT: Added 'message' to the layout to ensure it's visible.
          children = mkLiteral "[message, inputbar, listview]";
          spacing = mkLiteral "16px";
        };
        "inputbar" = {
          children = mkLiteral "[prompt, entry]";
          spacing = mkLiteral "12px";
          padding = mkLiteral "12px";
          border-radius = mkLiteral "12px";
          background-color = mkLiteral "#${config.stylix.base16Scheme.base01}66"; # More visible background
        };
        "listview" = {
          # --- KEY CHANGE: From grid to list ---
          columns = 1;
          lines = 8; # Adjust as needed for more/fewer visible items
          spacing = mkLiteral "8px"; # Space between list items
          cycle = true;
          # Ensure listview itself has a transparent background
          background-color = mkLiteral "transparent";
        };
        "element" = {
          # --- KEY CHANGE: Horizontal item layout ---
          orientation = mkLiteral "horizontal";
          children = mkLiteral "[element-icon, element-text]";
          cursor = mkLiteral "pointer";
          spacing = mkLiteral "16px"; # Space between icon and text
          padding = mkLiteral "10px";
          border-radius = mkLiteral "12px";
        };
        "element-icon" = {
          # --- KEY CHANGE: Smaller icon for list view ---
          size = mkLiteral "1.5em";
          # Icons are now vertically centered in the list item
          vertical-align = mkLiteral "0.5";
        };
        "element-text" = {
          # --- KEY CHANGE: Left-aligned text ---
          horizontal-align = mkLiteral "0.0";
          vertical-align = mkLiteral "0.5";
          text-color = mkLiteral "inherit";
        };
        "element selected" = {
          background-color = mkLiteral "#${config.stylix.base16Scheme.base09}4D";
          text-color = mkLiteral "#${config.stylix.base16Scheme.base0C}";
        };
        "entry" = {
          placeholder = "";
          placeholder-color = mkLiteral "#${config.stylix.base16Scheme.base03}";
          text-color = mkLiteral "#${config.stylix.base16Scheme.base0C}";
          vertical-align = mkLiteral "0.5";
        };
        "prompt" = {
          text-color = mkLiteral "#${config.stylix.base16Scheme.base09}";
          vertical-align = mkLiteral "0.5";
        };
        "message" = {
          padding = mkLiteral "12px";
          border-radius = mkLiteral "12px";
          background-color = mkLiteral "#${config.stylix.base16Scheme.base01}4D";
        };
        "textbox" = {
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "#${config.stylix.base16Scheme.base0B}";
          horizontal-align = mkLiteral "0.5";
        };
      };
    };
  };
}
