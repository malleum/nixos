{
  unify.home = {
    config,
    pkgs,
    ...
  }: let
    getColorOrDefault = baseKey: defaultHex:
      if config ? stylix && config.stylix ? base16Scheme && config.stylix.base16Scheme ? ${baseKey}
      then "#${config.stylix.base16Scheme.${baseKey}}"
      else "#${defaultHex}";

    base00 = getColorOrDefault "base00" "12151a";
    base01 = getColorOrDefault "base01" "1e232b";
    base02 = getColorOrDefault "base02" "3a424d";
    base03 = getColorOrDefault "base03" "545f6f";
    base04 = getColorOrDefault "base04" "a0a9b6";
    base05 = getColorOrDefault "base05" "c5cbd3";
    base06 = getColorOrDefault "base06" "e1e4e9";
    base07 = getColorOrDefault "base07" "ffffff";
    base08 = getColorOrDefault "base08" "e55f67";
    base09 = getColorOrDefault "base09" "e2995c";
    base0A = getColorOrDefault "base0A" "f0c674";
    base0B = getColorOrDefault "base0B" "a7c080";
    base0C = getColorOrDefault "base0C" "88c0d0";
    base0D = getColorOrDefault "base0D" "5e9de5";
    base0E = getColorOrDefault "base0E" "b48ead";
    base0F = getColorOrDefault "base0F" "a6adc8";
  in {
    programs.zellij = {
      enable = true;
      settings = {
        theme = "stylix";
        themes.stylix = {
          fg = base05;
          bg = base00;
          black = base01;
          red = base08;
          green = base0B;
          yellow = base0A;
          blue = base0D;
          magenta = base0E;
          cyan = base0C;
          white = base05;
          orange = base09;
        };
        pane_frames = false;
        # default_layout = "compact";
        mouse_mode = true;
        copy_on_select = true;
        mirror_session = true;
        scroll_buffer_size = 10000;
        on_force_close = "detach";
        # simplified_ui = true;
        show_startup_tips = false;
        default_shell = "${pkgs.fish}/bin/fish";
        ui.pane_frames.rounded_corners = true;

        keybinds = {
          "shared_except \"locked\"" = {
            # Tab Navigation (Native, no pane creation side-effect)
            "bind \"Alt 1\"" = { GoToTab = 1; };
            "bind \"Alt 2\"" = { GoToTab = 2; };
            "bind \"Alt 3\"" = { GoToTab = 3; };
            "bind \"Alt 4\"" = { GoToTab = 4; };
            "bind \"Alt 5\"" = { GoToTab = 5; };
            "bind \"Alt 6\"" = { GoToTab = 6; };
            "bind \"Alt 7\"" = { GoToTab = 7; };
            "bind \"Alt 8\"" = { GoToTab = 8; };
            "bind \"Alt 9\"" = { GoToTab = 9; };
            "bind \"Alt 0\"" = { GoToTab = 10; }; # 0 goes to 10

            # Tab Management
            "bind \"Alt n\"" = { NewTab = {}; }; # Use this to create new tabs

            # Pane Management
            "bind \"Alt Shift q\"" = { CloseFocus = {}; };
            "bind \"Alt Enter\"" = { NewPane = {}; };
            "bind \"Alt t\"" = { NextSwapLayout = {}; };
            "bind \"Alt f\"" = { ToggleFloatingPanes = {}; };

            # Move Pane (Rearrange within tab)
            "bind \"Alt Shift h\"" = { MovePane = "Left"; };
            "bind \"Alt Shift l\"" = { MovePane = "Right"; };
            "bind \"Alt Shift j\"" = { MovePane = "Down"; };
            "bind \"Alt Shift k\"" = { MovePane = "Up"; };

            # Move Focus (Navigate between panes)
            "bind \"Alt h\"" = { MoveFocus = "Left"; };
            "bind \"Alt l\"" = { MoveFocus = "Right"; };
            "bind \"Alt j\"" = { MoveFocus = "Down"; };
            "bind \"Alt k\"" = { MoveFocus = "Up"; };

            "bind \"Alt =\"" = { Resize = "Increase"; };
            "bind \"Alt -\"" = { Resize = "Decrease"; };
          };
        };
      };
    };
  };
}
