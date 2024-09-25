{
  lib,
  config,
  ...
}: {
  options.sway.enable = lib.mkEnableOption "enables sway WMs";

  config = lib.mkIf config.sway.enable {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    home-manager.users.joshammer.wayland.windowManager.sway = {
      enable = true;
      config = let
        mod = "Mod4";
      in {
        input."*" = {
          xkb_layout = "us";
          xkb_variant = "dvorak";
          xkb_options = "caps:escape";
          repeat_delay = "225";
          repeat_rate = "50";
        };
        modifier = mod;
        keybindings = {
          "${mod}+return" = "exec foot";
          "${mod}+shift+return" = "exec kitty";

          "${mod}+b" = "exec brave";
          "${mod}+shift+b" = "exec firefox";

          "${mod}+d" = "exec vesktop";
          "${mod}+shift+d" = "exec brave 'https://teams.microsoft.com/v2/'";

          "${mod}+x" = "exec wl-copy 'https://xkcd.com/1475/'";
          "${mod}+shift+x" = ''exec wl-copy '"Do you feel blame? Are you mad? Do you feel like woosh kabob rob vanish, efranish bw-bwooch pajooj, bea-ramich agij gij gij gij googood, do blegehthethamis sergeant British frazzlebaga?"'';

          "${mod}+n" = "exec dunstctl close-all";
          "${mod}+shift+n" = "exec dunstctl set-paused true";
          "${mod}+control+n" = "exec dunstctl set-paused false";

          "${mod}+s" = "exec rofi -show drun";
          "${mod}+c" = "exec rofi -show calc -modi calc -no-show-match -no-sort -qalc-binary qalc | wl-copy";
          "${mod}+shift+e" = "exec rofi -modi emoji -show emoji";
          "${mod}+v" = "exec cliphist list | rofi -dmenu | cliphist decode | wl-copy";

          "${mod}+shift+q" = "kill";
          "${mod}+control+shift+semicolon" = "exit";
          "${mod}+shift+z" = "exec poweroff";
          "${mod}+control+z" = "exec reboot";

          "print" = "exec hyprshot -m output --clipboard-only";
          "${mod}+shift+print" = "exec, hyprshot -m window --clipboard-only";
          "${mod}+shift+s" = "exec hyprshot -m region --clipboard-only";
          "${mod}+control+s" = "exec wl-paste | swappy -f -";

          "${mod}+space" = "floating toggle";
          "${mod}+shift+space" = "floating toggle";

          "${mod}+a" = "focus parent";
          "${mod}+shift+a" = "focus child";

          "${mod}+escape" = "exec swaylock -c 000000";

          "${mod}+h" = "focus left";
          "${mod}+l" = "focus right";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";

          "${mod}+shift+h" = "move left";
          "${mod}+shift+l" = "move right";
          "${mod}+shift+j" = "move down";
          "${mod}+shift+k" = "move up";

          "${mod}+t" = "split v";
          "${mod}+shift+t" = "split h";

          "${mod}+o" = "move workspace to output next";
          "${mod}+f" = "fullscreen toggle";

          "${mod}+apostrophe" = "workspace number 1";
          "${mod}+comma" = "workspace number 2";
          "${mod}+period" = "workspace number 3";
          "${mod}+p" = "workspace number 4";
          "${mod}+y" = "workspace number 5";

          "${mod}+shift+apostrophe" = "move container to workspace number 1";
          "${mod}+shift+comma" = "move container to workspace number 2";
          "${mod}+shift+period" = "move container to workspace number 3";
          "${mod}+shift+p" = "move container to workspace number 4";
          "${mod}+shift+y" = "move container to workspace number 5";
        };
        bindkeysToCode = true;
      };
    };
  };
}
