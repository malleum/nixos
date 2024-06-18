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
    plugins = with pkgs; [(rofi-calc.override {rofi-unwrapped = pkgs.rofi-wayland-unwrapped;}) rofi-emoji];
    extraConfig = {
      kb-primary-paste = "Control+V,Shift+Insert";
      drun-display-format = "{icon} {name}";
      show-icons = true;
      hide-scrollbar = true;
      display-drun = " 󰀘  Apps =>  ";
      display-calc = " ⅀ Calc =>  ";
      display-run = "   Command =>  ";
    };
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
      b0 = "#${config.stylix.base16Scheme.base00}";
      b1 = "#${config.stylix.base16Scheme.base01}";
      b2 = "#${config.stylix.base16Scheme.base02}";
      b9 = "#${config.stylix.base16Scheme.base09}";
      ba = "#${config.stylix.base16Scheme.base0A}";
      bb = "#${config.stylix.base16Scheme.base0B}";
      bc = "#${config.stylix.base16Scheme.base0C}";
      bd = "#${config.stylix.base16Scheme.base0D}";
      clear = "#00000000";
    in {
      "*" = {
        width = 1000;
        height = 370;
        spacing = 4;
      };
      "element" = {
        padding = 0;
        border = 0;
        spacing = 0;
        cursor = mkLiteral "pointer";
        text-color = mkLiteral bb;
        background-color = mkLiteral b0;
      };
      "element selected" = {
        background-color = mkLiteral b1;
        text-color = mkLiteral bc;
      };
      "element-text" = {
        background-color = mkLiteral clear;
        text-color = mkLiteral "inherit";
        highlight = mkLiteral "inherit";
        cursor = mkLiteral "inherit";
      };
      "element-icon" = {
        background-color = mkLiteral clear;
        size = mkLiteral "2em";
        text-color = mkLiteral "inherit";
        cursor = mkLiteral "inherit";
      };
      "window" = {
        padding = 2;
        border = 3;
        background-color = mkLiteral b0;
      };
      "mainbox" = {
        padding = 2;
        border = 0;
        background-color = mkLiteral b0;
      };
      "message" = {
        padding = mkLiteral "1px";
        border-color = mkLiteral b0;
        border = 0;
        background-color = mkLiteral b0;
      };
      "textbox" = {
        background-color = mkLiteral b0;
        text-color = mkLiteral bc;
      };
      "listview" = {
        padding = mkLiteral "2px 0px 0px";
        scrollbar = false;
        spacing = mkLiteral "2px";
        fixed-height = 0;
        border-color = mkLiteral b0;
        border = 0;
        background-color = mkLiteral b0;
      };
      "inputbar" = {
        padding = mkLiteral "1px";
        spacing = 1;
        children = mkLiteral "[prompt, entry]";
        background-color = mkLiteral b0;
      };
      "entry" = {
        spacing = 1;
        text-color = mkLiteral b2;
        placeholder-color = mkLiteral b1;
        placeholder = "Type to filter";
        cursor = mkLiteral "text";
        background-color = mkLiteral b0;
      };
      "prompt" = {
        spacing = 0;
        text-color = mkLiteral b9;
        background-color = mkLiteral b0;
      };
    };
  };
}
