{
  pkgs,
  lib,
  config,
  ...
}: {
  options.sway.enable = lib.mkEnableOption "Enables sway";
  config = lib.mkIf config.sway.enable {
    programs.sway = {
      enable = true;
      package = pkgs.swayfx;
      wrapperFeatures.gtk = true;
    };

    home-manager.users.joshammer = {
      pkgs,
      config,
      lib,
      osConfig,
      ...
    }: {
      wayland.windowManager.sway = {
        enable = true;
        config = {
          modifier = "Mod4";
          bindkeysToCode = true;
          defaultWorkspace = "workspace number 1";
          focus = {wrapping = "yes";};
          input."*" = {
            xkb_layout = "us,us";
            xkb_variant = "dvorak,";
            xkb_options = "caps:escape";
            repeat_delay = "225";
            repeat_rate = "50";
            tap = "enabled";
            "dwt" = "disabled";
            natural_scroll =
              if (osConfig.networking.hostName == "magnus")
              then "disabled"
              else "enabled";
          };
          bars = [];
          seat."*" = {
            hide_cursor = "when-typing enable";
          };
          startup = [
            {command = "waybar";}
            {command = "wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";}
            {command = "vesktop";}
            {command = "nm-applet";}
            {command = "spotify_player -d";}
            {command = "onedrive --monitor";}
          ];
          assigns = {
            "1" = [{title = "(Brave|Firefox)";}];
            "2" = [{title = "(Discord|vesktop|Microsoft Teams)";}];
            "3" = [{title = "(foot|ghostty)";}];
            "4" = [{title = "(Steam|Minecraft|War)";}];
            "5" = [{title = "OBS";}];
          };
          window = {
            titlebar = false;
            commands = [
              {
                command = "focus";
                criteria.class = "";
              }
            ];
          };
          floating = {
            titlebar = false;
            criteria = [{title = "All Files";}];
          };
          keybindings = let
            m = config.wayland.windowManager.sway.config.modifier;
            ms = "${m}+Shift";
            mc = "${m}+Control";
            mcs = "${m}+Control+Shift";
            wkspaces = {
              apostrophe = "1";
              comma = "2";
              period = "3";
              p = "4";
              y = "5";
            };
            lettertodirection = {
              j = "down";
              k = "up";
              l = "right";
              h = "left";
            };
            many = mod: action: set: lib.attrsets.mapAttrs' (key: num: lib.attrsets.nameValuePair "${mod}+${key}" (builtins.replaceStrings ["#"] [num] action)) set;
          in
            {
              "${m}+return" = "exec foot";
              "${ms}+return" = "exec ghostty";
              "${m}+b" = "exec brave";
              "${ms}+b" = "exec firefox";
              "${m}+d" = "exec vesktop";
              "${ms}+d" = "exec brave 'https://teams.microsoft.com/v2/'";

              "${m}+x" = "exec wl-copy 'https://xkcd.com/1475/'";
              "${mc}+b" = "exec wl-copy '\"Do you feel blame? Are you mad? Do you feel like woosh kabob rob vanish, efranish bw-bwooch pajooj, bea-ramich agij gij gij gij googood, do blegehthethamis sergeant British frazzlebaga?\"'";

              "${m}+n" = "exec dunstctl close-all";
              "${ms}+n" = "exec dunstctl set-paused toggle";

              # "${m}+backslash" = "exec hyprctl switchxkblayout all next";

              "${m}+s" = "exec rofi -show drun";
              "${m}+c" = "exec rofi -show calc -modi calc -no-show-match -no-sort -qalc-binary qalc | wl-copy";
              "${ms}+e" = "exec rofi -modi emoji -show emoji";
              "${m}+v" = "exec ${pkgs.cliphist}/bin/cliphist list | rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | wl-copy";

              "${ms}+r" = "reload";
              "${m}+r" = "mode resize";
              "${ms}+q" = "kill";
              "${mcs}+semicolon" = "exit";
              "${ms}+z" = "exec poweroff";
              "${mc}+z" = "exec reboot";

              "print" = "exec ${pkgs.hyprshot}/bin/hyprshot -m output --clipboard-only";
              "Shift+print" = "exec ${pkgs.hyprshot}/bin/hyprshot -m window --clipboard-only";
              "${ms}+s" = "exec ${pkgs.hyprshot}/bin/hyprshot -m region --clipboard-only";
              "${mc}+s" = "exec wl-paste | ${pkgs.swappy}/bin/swappy -f -";

              "${m}+space" = "floating toggle";
              "${m}+t" = "layout toggle slpit";

              "${m}+f" = "fullscreen toggle";

              "${m}+escape" = "exec ${pkgs.swaylock}/bin/swaylock -c 000000"; # escape

              "${m}+bracketright" = "exec 'killall .waybar-wrapped; waybar'";
              "${mc}+d" = "exec killall .Discord-wrappe";
              "${mcs}+d" = "exec killall .electron-wrapp";

              "${m}+o" = "move workspace to output right; focus right";
              "${ms}+o" = "move workspace to output left; focus left";

              "xf86audiolowervolume" = "exec pulsemixer --change-volume -5";
              "xf86audioraisevolume" = "exec pulsemixer --change-volume +5";
              "xf86audiomute" = "exec pulsemixer --toggle-mute";
              "xf86monbrightnessup" = "exec xbacklight -inc 10";
              "xf86monbrightnessdown" = "exec xbacklight -dec 10";
            }
            // many m "workspace number #" wkspaces
            // many ms "move container to workspace number #; workspace number #" wkspaces
            // many m "focus #" lettertodirection
            // many ms "move #" lettertodirection;
        };
      };
    };
  };
}
