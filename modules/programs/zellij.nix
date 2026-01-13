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
      };
    };
  };
}
