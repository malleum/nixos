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
      package = pkgs.rofi-wayland;
      terminal = "foot";
      location = "center";
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

      # A single, unified theme definition.
      theme = {
        "*" = {
          background-color = mkLiteral "#00000000";
          text-color = mkLiteral "#${config.stylix.base16Scheme.base05}";
        };
        "window" = {
          location = mkLiteral "center";
          anchor = mkLiteral "center";
          width = mkLiteral "45%";
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
          background-color = mkLiteral "#${config.stylix.base16Scheme.base01}33";
        };
        "listview" = {
          columns = 6;
          lines = 3;
          spacing = mkLiteral "12px";
          cycle = true;
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
        };
        "element-text" = {
          horizontal-align = mkLiteral "0.5";
          text-color = mkLiteral "inherit";
        };
        "element selected" = {
          background-color = mkLiteral "#${config.stylix.base16Scheme.base09}4D";
          text-color = mkLiteral "#${config.stylix.base16Scheme.base0C}";
        };
        "entry" = {
          placeholder = "Search or Calculate...";
          placeholder-color = mkLiteral "#${config.stylix.base16Scheme.base02}";
          text-color = mkLiteral "#${config.stylix.base16Scheme.base0C}";
        };
        "prompt" = {
          text-color = mkLiteral "#${config.stylix.base16Scheme.base09}";
        };

        "message" = {
          padding = mkLiteral "12px";
          border-radius = mkLiteral "12px";
          background-color = mkLiteral "#${config.stylix.base16Scheme.base01}4D";
        };
        "textbox" = {
          # This is the box that holds the live answer text.
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "#${config.stylix.base16Scheme.base0B}"; # A bright, readable color for the result
          font = "JetBrainsMono Nerd Font 12";
          horizontal-align = mkLiteral "0.5";
        };
      };
    };
  };
}
