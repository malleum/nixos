{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    # home-manager.users.joshammer.wayland.windowManager.sway = {
    #   enable = true;
    #   settings = lib.mkForce {
    #     monitor =
    #       if config.networking.hostName == "magnus"
    #       then [
    #         "DP-1,1920x1080@165.00Hz,0x0,1"
    #         "desc:HP Inc. HP V222vb 3CQ1261KNM,1920x1080,0x1080,1"
    #       ]
    #       else [
    #         "desc:LG Display 0x06F9,preferred,0x0,1" # laptop screen
    #         "desc:LG Electronics LG ULTRAGEAR 406NTAB8X168,highres,auto-right,1,transform,3" # right monitor
    #         "desc:LG Electronics LG ULTRAGEAR 406NTHM8X153,highres,auto-left,1,transform,1" # left monitor
    #         ",preferred,auto,1"
    #       ];
    #
    #     exec-once = [
    #       "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    #       "waybar"
    #       "wl-paste --watch ${pkgs.stable.cliphist}/bin/cliphist store"
    #       "vesktop"
    #       "nm-applet"
    #       "onedrive --monitor"
    #     ];
    #
    #     input = {
    #       kb_layout = "us, us";
    #       kb_variant = "dvorak,";
    #       kb_options = "caps:escape";
    #
    #       follow_mouse = 1;
    #
    #       touchpad.natural_scroll = true;
    #
    #       sensitivity = 0;
    #       repeat_delay = 225;
    #       repeat_rate = 50;
    #     };
    #     general = {
    #       gaps_in = 5;
    #       gaps_out = 15;
    #       border_size = 2;
    #       layout = "dwindle, master";
    #
    #       "col.active_border" = "rgba(${config.stylix.base16Scheme.base04}ff) rgba(${config.stylix.base16Scheme.base0C}ff) 30deg";
    #       "col.inactive_border" = "rgba(${config.stylix.base16Scheme.base01}aa)";
    #     };
    #
    #     decoration = {
    #       rounding = 20;
    #
    #       blur = {
    #         enabled = true;
    #         size = 3;
    #         passes = 1;
    #       };
    #
    #       shadow = {
    #         enabled = true;
    #         range = 4;
    #         render_power = 3;
    #         color = "rgba(1a1a1aee)";
    #       };
    #     };
    #
    #     misc.disable_hyprland_logo = true;
    #
    #     animations = {
    #       enabled = true;
    #
    #       bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
    #
    #       animation = let
    #         slide = "${
    #           if config.networking.hostName == "magnus"
    #           then "slidevert"
    #           else "slide"
    #         }";
    #       in [
    #         "windows, 1, 7, myBezier, ${slide}"
    #         "windowsOut, 1, 7, default, popin 80%"
    #         "border, 1, 10, default"
    #         "borderangle, 1, 8, default"
    #         "fade, 1, 7, default"
    #         "workspaces, 1, 6, default, ${slide}"
    #       ];
    #     };
    #
    #     dwindle.preserve_split = true;
    #
    #     gestures. workspace_swipe = false;
    #     layerrule = "blur,rofi";
    #
    #     windowrulev2 = [
    #       "workspace 1, title:^(.*Brave.*)$"
    #       "workspace 2, title:^(.*Discord.*)$"
    #       "workspace 2, title:^(.*Microsoft Teams.*)$"
    #       "workspace 3, title:^(kitty)$"
    #       "workspace 3, title:^(foot)$"
    #       "workspace 4, title:^(.*Steam.*)$"
    #       "workspace 4, title:^(.*Minecraft.*)$"
    #       "workspace 4, title:^(.*Terraria.*)$"
    #       "workspace 4, title:^(.*War.*)$"
    #
    #       "float, title:^(.*All Files.*)$"
    #       "float, title:^(.*War.*Settings.*)$"
    #       "fullscreen, title:^(.*War(?!Settings))$"
    #       # "opacity .7, title:^(.*Discord.*)$"
    #     ];
    #
    #     bind = let
    #       wkspaces = {
    #         apostrophe = "1";
    #         comma = "2";
    #         period = "3";
    #         p = "4";
    #         y = "5";
    #       };
    #       lettertodirection = {
    #         j = "d";
    #         k = "u";
    #         l = "r";
    #         h = "l";
    #       };
    #       many = mod: action: set: lib.attrsets.mapAttrsToList (key: num: "${mod},${key},${action},${num}") set;
    #     in
    #       [
    #         "SUPER, return, exec, foot"
    #         "SUPER SHIFT, return, exec, kitty"
    #         "SUPER, b, exec, brave"
    #         "SUPER SHIFT, b, exec, chromium"
    #         "SUPER, d, exec, vesktop"
    #         "SUPER SHIFT, d, exec, brave 'https://teams.microsoft.com/v2/'"
    #
    #         "SUPER, x, exec, wl-copy 'https://xkcd.com/1475/'"
    #         "SUPER CONTROL, b, exec, wl-copy '\"Do you feel blame? Are you mad? Do you feel like woosh kabob rob vanish, efranish bw-bwooch pajooj, bea-ramich agij gij gij gij googood, do blegehthethamis sergeant British frazzlebaga?\"'"
    #
    #         "SUPER, n, exec, dunstctl close-all"
    #         "SUPER SHIFT, n, exec, dunstctl set-paused toggle"
    #
    #         "SUPER, backslash, exec, hyprctl switchxkblayout all next"
    #         "SUPER SHIFT, tab, exec, hyprctl keyword input:kb_options caps:escape"
    #         "SUPER CONTROL, tab, exec, hyprctl keyword input:kb_options ''"
    #
    #         "SUPER, s, exec, rofi -show drun"
    #         "SUPER, c, exec, rofi -show calc -modi calc -no-show-match -no-sort -qalc-binary qalc | wl-copy"
    #         "SUPER SHIFT, e, exec, rofi -modi emoji -show emoji"
    #         "SUPER, v, exec, ${pkgs.stable.cliphist}/bin/cliphist list | rofi -dmenu | ${pkgs.stable.cliphist}/bin/cliphist decode | wl-copy"
    #
    #         "SUPER SHIFT, q, killactive"
    #         "SUPER CONTROL SHIFT, semicolon, exit"
    #         "SUPER SHIFT, z, exec, poweroff"
    #         "SUPER CONTROL, z, exec, reboot"
    #
    #         ", print, exec, ${pkgs.hyprshot}/bin/hyprshot -m output --clipboard-only"
    #         "SHIFT, print, exec, ${pkgs.hyprshot}/bin/hyprshot -m window --clipboard-only"
    #         "SUPER SHIFT, s, exec, ${pkgs.hyprshot}/bin/hyprshot -m region --clipboard-only"
    #         "SUPER CONTROL, s, exec, wl-paste | ${pkgs.swappy}/bin/swappy -f -"
    #
    #         "SUPER, space, togglefloating,"
    #         "SUPER, t, togglesplit,"
    #
    #         "SUPER, f, fullscreen, 1"
    #         "SUPER SHIFT, f, fullscreen, 0"
    #
    #         "SUPER, code:9, exec, ${pkgs.swaylock}/bin/swaylock -c 000000" # escape
    #
    #         "SUPER, bracketleft, exec, killall hyprpaper; hyprpaper"
    #         "SUPER, bracketright, exec, killall .waybar-wrapped; waybar"
    #         "SUPER CONTROL, d, exec, killall .Discord-wrappe"
    #         "SUPER CONTROL SHIFT, d, exec, killall electron"
    #
    #         "SUPER, o, movecurrentworkspacetomonitor, +1"
    #         "SUPER SHIFT, o, movecurrentworkspacetomonitor, -1"
    #
    #         # Scroll through existing workspaces with m + scroll
    #         "SUPER, mouse_down, workspace, e+1"
    #         "SUPER, mouse_up, workspace, e-1"
    #
    #         ", xf86audiolowervolume, exec, pulsemixer --change-volume -5"
    #         ", xf86audioraisevolume, exec, pulsemixer --change-volume +5"
    #         ", xf86audiomute, exec, pulsemixer --toggle-mute"
    #         ", xf86monbrightnessup, exec, xbacklight -inc 10"
    #         ", xf86monbrightnessdown, exec, xbacklight -dec 10"
    #       ]
    #       ++ many "SUPER" "workspace" wkspaces
    #       ++ many "SUPER SHIFT" "movetoworkspace" wkspaces
    #       ++ many "SUPER" "movefocus" lettertodirection
    #       ++ many "SUPER SHIFT" "movewindow" lettertodirection;
    #
    #     bindm = [
    #       # Move/resize windows with m + LMB/RMB and dragging
    #       "SUPER, mouse:272, movewindow"
    #       "SUPER, mouse:273, resizewindow"
    #     ];
    #   };
    # };
  };
}