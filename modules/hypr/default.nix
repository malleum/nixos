{
  lib,
  config,
  ...
}: {
  imports = [./waybar.nix];

  options.hypr.enable = lib.mkEnableOption "enables hyprland";

  config = lib.mkIf config.hypr.enable {
    programs.hyprland.enable = true;

    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };

    home-manager.users.joshammer = {
      wayland.windowManager.hyprland = {
        enable = true;
        settings = {
          monitor =
            if config.networking.hostName == "magnus"
            then [
              "DP-1,1920x1080@165.00Hz,0x0,1"
              "desc:HP Inc. HP V222vb 3CQ1261KNM,1920x1080,0x1080,1"
            ]
            else [
              "desc:LG Display 0x06F9,preferred,0x0,1" # laptop screen
              "desc:LG Electronics LG ULTRAGEAR 406NTAB8X168,highres,auto-right,1,transform,3" # right monitor
              "desc:LG Electronics LG ULTRAGEAR 406NTHM8X153,highres,auto-left,1,transform,1" # left monitor
              ",preferred,auto,1"
            ];

          exec-once = ["startup"];

          input = {
            kb_layout = "us, us";
            kb_variant = "dvorak,";
            kb_options = "caps:escape";

            follow_mouse = 1;

            touchpad = {
              natural_scroll = true;
            };

            sensitivity = 0;
            repeat_delay = 225;
            repeat_rate = 50;
          };
          general = {
            gaps_in = 5;
            gaps_out = 15;
            border_size = 2;
            layout = "dwindle, master";

            "col.active_border" = "rgba(${config.stylix.base16Scheme.base04}ff) rgba(${config.stylix.base16Scheme.base0C}ff) 30deg";
            "col.inactive_border" = "rgba(${config.stylix.base16Scheme.base01}aa)";
          };

          decoration = {
            rounding = 20;

            blur = {
              enabled = true;
              size = 3;
              passes = 1;
            };

            drop_shadow = true;
            shadow_range = 4;
            shadow_render_power = 3;
            col.shadow = "rgba(1a1a1aee)";
          };

          misc = {
            disable_hyprland_logo = true;
          };
        };
      };
    };
  };
}
