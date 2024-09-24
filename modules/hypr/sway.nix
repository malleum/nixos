{
  lib,
  config,
  pkgs,
  ...
}: {
  options.sway.enable = lib.mkEnableOption "enables sway WMs";

  config = lib.mkIf config.sway.enable {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    home-manager.users.joshammer.wayland.windowManager.sway = let
      s = config.home-manager.users.joshammer.wayland.windowManager.sway;
    in {
      enable = true;
      config = {
        input."*" = {
          xkb_layout = "us, us";
          xkb_variant = "dvorak, ";
          xkb_options = "caps:escape";
          repeat_delay = 225;
          repeat_rate = 20;
        };
        modifier = "mod4";
        keybinds = let
          m = s.config.modifier;
        in
          lib.mkOptionDefault {
            "${m}+Return" = "exec foot";
            "${m}+d" = "exec vesktop";
            "${m}+Shift+q" = "kill";
          };
      };
    };
  };
}
