{inputs, ...}: {
  unify.modules.gui.nixos = {pkgs, ...}: {
    programs.hyprland = {
      enable = true;
      package = inputs.hypr.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hypr.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
  };

  unify.modules.gui.home = {
    config,
    hostConfig,
    lib,
    pkgs,
    ...
  }: let
    wallpaper = config.stylix.image;

    mkLua = lib.generators.mkLuaInline;
    mkBind = key: disp: {_args = [key (mkLua disp)];};
    mkBindM = key: disp: {_args = [key (mkLua disp) {mouse = true;}];};

    wkspaces = {
      apostrophe = "1";
      comma = "2";
      period = "3";
      p = "4";
      y = "5";
    };
    lettertodirection = {
      h = "left";
      j = "down";
      k = "up";
      l = "right";
    };
    many = mod: f: set:
      lib.attrsets.mapAttrsToList (key: val: mkBind "${mod} + ${key}" (f val)) set;

    slide =
      if hostConfig.name == "magnus"
      then "slidevert"
      else "slide";
  in {
    xdg.portal = {
      enable = true;
      extraPortals = [
        inputs.hypr.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hypr.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hypr.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      configType = "lua";
      settings = lib.mkForce {
        env = [
          {_args = ["WLR_NO_HARDWARE_CURSORS" "1"];}
          {_args = ["NIXOS_OZONE_WL" "1"];}
          # Prefer Wayland, fallback to X11
          {_args = ["GDK_BACKEND" "wayland,x11"];}
          # VAAPI for hardware video decoding
          {_args = ["LIBVA_DRIVER_NAME" "radeonsi"];}
          # Firefox settings
          {_args = ["MOZ_ENABLE_WAYLAND" "1"];}
          {_args = ["MOZ_WEBRENDER" "1"];}
          {_args = ["MOZ_ACCELERATED" "1"];}
        ];

        monitor =
          if hostConfig.name == "magnus"
          then [
            {
              output = "desc:HKC OVERSEAS LIMITED 25E3A 0000000000001";
              mode = "1920x1080@180.00";
              position = "0x0";
              scale = 1;
            }
            {
              output = "desc:HP Inc. HP V222vb 3CQ1261KNM";
              mode = "1920x1080";
              position = "-1920x0";
              scale = 1;
            }
          ]
          else if hostConfig.name == "manus"
          then [
            {
              output = "desc:Lenovo Group Limited 0x4146";
              mode = "1920x1200@60.00";
              position = "0x0";
              scale = 1;
            }
            {
              # left monitor
              output = "desc:LG Electronics LG ULTRAGEAR 0x0004A026";
              mode = "2560x1440@60.00Hz";
              position = "-2560x-240";
              scale = 1;
            }
            {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = 1;
            }
          ]
          else [
            {
              # laptop screen
              output = "desc:LG Display 0x06F9";
              mode = "preferred";
              position = "0x0";
              scale = 1;
            }
            {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = 1;
            }
          ];

        config = {
          general = {
            gaps_in = 5;
            gaps_out = 15;
            border_size = 2;
            layout = "dwindle";

            col = {
              active_border = {
                colors = [
                  "rgba(${config.stylix.base16Scheme.base04}ff)"
                  "rgba(${config.stylix.base16Scheme.base0C}ff)"
                ];
                angle = 30;
              };
              inactive_border = "rgba(${config.stylix.base16Scheme.base01}aa)";
            };
          };

          ecosystem = {
            no_update_news = true;
            no_donation_nag = true;
          };

          decoration = {
            rounding = 20;

            blur = {
              enabled = true;
              size = 3;
              passes = 1;
            };

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              color = "rgba(1a1a1aee)";
            };
          };

          misc.disable_hyprland_logo = true;

          animations.enabled = true;

          dwindle.preserve_split = true;
          binds.movefocus_cycles_fullscreen = true;

          input = {
            kb_layout = "us,us";
            kb_variant = "dvorak,";
            kb_options = "caps:escape,compose:ins";

            follow_mouse = 1;

            touchpad = {
              natural_scroll = true;
              disable_while_typing = true;
            };

            accel_profile = "flat";
            sensitivity = 0;
            repeat_delay = 225;
            repeat_rate = 50;
          };
        };

        curve = [
          {_args = ["myBezier" {type = "bezier"; points = [[0.05 0.9] [0.1 1.05]];}];}
        ];

        animation = [
          {leaf = "windows"; enabled = true; speed = 7; bezier = "myBezier"; style = slide;}
          {leaf = "windowsOut"; enabled = true; speed = 7; bezier = "default"; style = "popin 80%";}
          {leaf = "border"; enabled = true; speed = 10; bezier = "default";}
          {leaf = "borderangle"; enabled = true; speed = 8; bezier = "default";}
          {leaf = "fade"; enabled = true; speed = 7; bezier = "default";}
          {leaf = "workspaces"; enabled = true; speed = 6; bezier = "default"; style = slide;}
        ];

        gesture = [
          {fingers = 3; direction = "horizontal"; action = "workspace";}
          {fingers = 3; direction = "vertical"; action = "move";}
        ];

        layer_rule = [
          {match = {namespace = "rofi";}; blur = true;}
        ];

        window_rule = [
          {match.title = "^(.*Microsoft Teams.*)$"; workspace = "2";}

          {match.title = "^(.*Brave.*)$"; workspace = "1";}
          {match.title = "^(.*Firefox.*)$"; workspace = "1";}
          {match.title = "^(.*Ninjabrain Bot.*)$"; workspace = "1";}
          {match.title = "^(.*e4mc.*)$"; workspace = "1";}
          {match.title = "^(iamb.*)$"; workspace = "2";}
          {match.title = "^(kitty)$"; workspace = "3";}
          {match.title = "^(foot)$"; workspace = "3";}
          {match.title = "^(.*Steam.*)$"; workspace = "4";}
          {match.title = "^(.*Minecraft.*)$"; workspace = "4";}
          {match.title = "^(.*Prism Launcher.*)$"; workspace = "4";}
          {match.title = "^(.*Terraria.*)$"; workspace = "4";}
          {match.title = "^(.*War.*)$"; workspace = "4";}
          {match.title = "^(.*OBS.*)$"; workspace = "5";}
          {match.title = "^(.*MainPicker.*)$"; workspace = "5";}
          {match.title = "^(Signal)$"; workspace = "5";}
          {match.title = "^(.*Discord.*)$"; workspace = "5";}

          {match.title = "^(.*(All|Save) Files?.*)$"; float = true;}
        ];

        on = {
          _args = [
            "hyprland.start"
            (mkLua ''
              function()
                hl.exec_cmd("nm-applet")
                hl.exec_cmd("awww-daemon && awww img ${wallpaper}")
                hl.exec_cmd("waybar")
                hl.exec_cmd("sleep 2")
                hl.exec_cmd("signal-desktop")
                hl.exec_cmd("$TERMINAL iamb")
              end'')
          ];
        };

        bind =
          [
            (mkBind "SUPER + return" ''hl.dsp.exec_cmd("$TERMINAL")'')
            (mkBind "SUPER + SHIFT + return" ''hl.dsp.exec_cmd("kitty")'')
            (mkBind "SUPER + b" ''hl.dsp.exec_cmd("$BROWSER")'')
            (mkBind "SUPER + SHIFT + b" ''hl.dsp.exec_cmd("$BROWSER2")'')
            (mkBind "SUPER + d" ''hl.dsp.exec_cmd("vesktop")'')
            (mkBind "SUPER + SHIFT + d" ''hl.dsp.exec_cmd("$BROWSER 'https://teams.microsoft.com/v2/'")'')
            (mkBind "SUPER + i" ''hl.dsp.exec_cmd("$TERMINAL iamb")'')
            (mkBind "SUPER + SHIFT + i" ''hl.dsp.exec_cmd("signal-desktop")'')

            (mkBind "SUPER + x" ''hl.dsp.exec_cmd("wl-copy 'https://xkcd.com/1475/'")'')
            (mkBind "SUPER + SHIFT + x" ''hl.dsp.exec_cmd("wl-copy 'Neida, jeg ville vinne'")'')
            (mkBind "SUPER + CONTROL + x" ''hl.dsp.exec_cmd([[wl-copy '"Do you feel blame? Are you mad? Do you feel like woosh kabob rob vanish, efranish bw-bwooch pajooj, bea-ramich agij gij gij gij googood, do blegehthethamis sergeant British frazzlebaga?"']])'')

            (mkBind "SUPER + n" ''hl.dsp.exec_cmd("swaync-client --close-all")'')
            (mkBind "SUPER + SHIFT + n" ''hl.dsp.exec_cmd("swaync-client --dnd-off && notify-send 'Notifications Enabled' -t 1000")'')
            (mkBind "SUPER + CONTROL + n" ''hl.dsp.exec_cmd("notify-send 'Notifications Disabled' -t 300; sleep 0.3; swaync-client --dnd-on")'')
            (mkBind "SUPER + SHIFT + CONTROL + n" ''hl.dsp.exec_cmd("swaync-client -a 0")'')

            (mkBind "SUPER + backslash" ''hl.dsp.exec_cmd("hyprctl switchxkblayout all next")'')

            (mkBind "SUPER + s" ''hl.dsp.exec_cmd("rofi -show drun")'')
            (mkBind "SUPER + c" ''hl.dsp.exec_cmd("rofi -theme-str 'window {width: 75%;}' -show calc -modi calc -no-show-match -no-sort -qalc-binary qalc | wl-copy")'')
            (mkBind "SUPER + SHIFT + e" ''hl.dsp.exec_cmd("rofi -modi emoji -show emoji")'')
            (mkBind "SUPER + v" ''hl.dsp.exec_cmd("${pkgs.cliphist}/bin/cliphist list | rofi -theme-str 'window {width: 75%;}' -dmenu | ${pkgs.cliphist}/bin/cliphist decode | wl-copy")'')
            (mkBind "SUPER + CONTROL + SHIFT + s" ''hl.dsp.exec_cmd("themeswitcher")'')

            (mkBind "SUPER + SHIFT + q" ''hl.dsp.window.close()'')
            (mkBind "SUPER + CONTROL + SHIFT + semicolon" ''hl.dsp.exit()'')
            (mkBind "SUPER + SHIFT + z" ''hl.dsp.exec_cmd("poweroff")'')
            (mkBind "SUPER + CONTROL + z" ''hl.dsp.exec_cmd("reboot")'')

            (mkBind "print" ''hl.dsp.exec_cmd("${pkgs.hyprshot}/bin/hyprshot -m active -z --clipboard-only")'')
            (mkBind "SHIFT + print" ''hl.dsp.exec_cmd("${pkgs.hyprshot}/bin/hyprshot -m region -z --clipboard-only")'')
            (mkBind "SUPER + SHIFT + s" ''hl.dsp.exec_cmd("${pkgs.hyprshot}/bin/hyprshot -m region --clipboard-only")'')
            (mkBind "SUPER + CONTROL + s" ''hl.dsp.exec_cmd("wl-paste | ${pkgs.swappy}/bin/swappy -f -")'')

            (mkBind "SUPER + space" ''hl.dsp.window.float({ action = "toggle" })'')
            (mkBind "SUPER + t" ''hl.dsp.layout("togglesplit")'')

            (mkBind "SUPER + f" ''hl.dsp.window.fullscreen({ mode = "maximized" })'')
            (mkBind "SUPER + SHIFT + f" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'')

            (mkBind "SUPER + Backspace" ''hl.dsp.exec_cmd("${pkgs.swaylock}/bin/swaylock -c 000000")'')

            (mkBind "SUPER + bracketleft" ''hl.dsp.exec_cmd("awww kill; awww-daemon && awww img ${wallpaper}")'')
            (mkBind "SUPER + bracketright" ''hl.dsp.exec_cmd("pkill waybar; sleep 0.5 && waybar")'')
            (mkBind "SUPER + CONTROL + bracketleft" ''hl.dsp.exec_cmd("awww kill")'')
            (mkBind "SUPER + CONTROL + bracketright" ''hl.dsp.exec_cmd("pkill waybar")'')
            (mkBind "SUPER + CONTROL + d" ''hl.dsp.exec_cmd("killall electron")'')
            (mkBind "SUPER + CONTROL + SHIFT + d" ''hl.dsp.exec_cmd("killall .electron-wrapp; killall electron")'')

            (mkBind "SUPER + o" ''hl.dsp.workspace.move({ monitor = "+1" })'')
            (mkBind "SUPER + SHIFT + o" ''hl.dsp.workspace.move({ monitor = "-1" })'')

            # Scroll through existing workspaces with SUPER + scroll
            (mkBind "SUPER + mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'')
            (mkBind "SUPER + mouse_up" ''hl.dsp.focus({ workspace = "e-1" })'')

            (mkBind "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("pulsemixer --change-volume -5")'')
            (mkBind "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("pulsemixer --change-volume +5")'')
            (mkBind "XF86AudioMute" ''hl.dsp.exec_cmd("pulsemixer --toggle-mute")'')
            (mkBind "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("xbacklight -inc 10")'')
            (mkBind "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("xbacklight -dec 10")'')

            # Move/resize windows with SUPER + LMB/RMB and dragging
            (mkBindM "SUPER + mouse:272" ''hl.dsp.window.drag()'')
            (mkBindM "SUPER + mouse:273" ''hl.dsp.window.resize()'')
          ]
          ++ many "SUPER" (n: ''hl.dsp.focus({ workspace = ${n} })'') wkspaces
          ++ many "SUPER + SHIFT" (n: ''hl.dsp.window.move({ workspace = ${n} })'') wkspaces
          ++ many "SUPER" (d: ''hl.dsp.focus({ direction = "${d}" })'') lettertodirection
          ++ many "SUPER + SHIFT" (d: ''hl.dsp.window.move({ direction = "${d}" })'') lettertodirection;
      };
    };
  };
}
