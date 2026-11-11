{inputs, ...}: {
  flake.modules.nixos.hyp = {pkgs, ...}: {
    programs.hyprland = {
      enable = true;
      package = inputs.hypr.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hypr.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
  };

  flake.modules.homeManager.hyp = {
    config,
    hostConfig,
    lib,
    pkgs,
    ...
  }: let
    wallpaper = config.stylix.image;

    # Launchers, commands and window rules shared with jay (../_desktop.nix).
    scripts = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
    desktop = import ./_desktop.nix {
      inherit pkgs lib;
      compositor = "hyprland";
      hostName = hostConfig.name;
      inherit (hostConfig.user) browser browser2;
      workBrowser =
        if config.programs.firefox.profiles ? work
        then "firefox-work"
        else null;
      workPrimary = config.work.primary;
      lock = import ./jay/_lock.nix {
        inherit pkgs wallpaper;
        colors = config.stylix.base16Scheme;
      };
      windowSwitch = scripts.jay-window-switch;
      audioSwitch = scripts.jay-audio-switch;
    };

    mkLua = lib.generators.mkLuaInline;
    mkBind = key: disp: {_args = [key (mkLua disp)];};
    mkBindM = key: disp: {_args = [key (mkLua disp) {mouse = true;}];};
    # Lua long brackets need no escaping.
    luaStr = str: "[==[${str}]==]";

    # "MOD-ctrl-shift-b" -> "SUPER + CONTROL + SHIFT + b"
    hyprKey = key:
      lib.concatStringsSep " + " (map (part:
        {
          MOD = "SUPER";
          shift = "SHIFT";
          ctrl = "CONTROL";
          alt = "ALT";
        }
        .${
          part
        }
        or part) (lib.splitString "-" key));
    sharedBinds =
      map (b: mkBind (hyprKey b.key) "hl.dsp.exec_cmd(${luaStr (b.sh or (lib.escapeShellArgs b.argv))})")
      desktop.binds;
    # jay's title matches are regexes written as full matches; hyprland
    # anchors its own. notTitle and justMapped are jay-only.
    sharedRules = map (r: let
      m = r.match;
    in
      {
        match =
          lib.optionalAttrs (m ? title) {title = "^(${m.title})$";}
          // lib.optionalAttrs (m ? titleExact) {title = "^(${m.titleExact})$";}
          // lib.optionalAttrs (m ? appId) {class = "^(${m.appId})$";}
          // lib.optionalAttrs (m ? appIdRegex) {class = m.appIdRegex;};
      }
      // lib.optionalAttrs (r ? workspace) {inherit (r) workspace;}
      // lib.optionalAttrs (r.float or false) {float = true;})
    desktop.rules;

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
    # Only the GTK portal is session-agnostic. The Hyprland portal is picked up
    # from programs.hyprland.portalPackage on the NixOS side and selected by
    # hyprland-portals.conf when XDG_CURRENT_DESKTOP=Hyprland; under jay,
    # jay-portals.conf routes ScreenCast/RemoteDesktop to jay's own portal and
    # FileChooser to gtk4. Listing the Hyprland portal here too just installed
    # a second implementation into the jay session for nothing.
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
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

        # Kept in step with the [[outputs]] blocks in jay.nix — jay is the
        # daily driver, hyprland is the fallback session, and a fallback with
        # the wrong layout is worse than useless. `desc:` substring-matches
        # "make model serial", so model/serial fragments are enough and are
        # stabler than connectors (manus' left LG floats DP-1 <-> DP-2).
        monitor =
          if hostConfig.name == "magnus"
          then [
            {
              # left
              output = "desc:VFD40M-0809";
              mode = "1920x1080@60.00";
              position = "0x0";
              scale = 1;
            }
            {
              # middle
              output = "desc:HP V222vb 3CQ1261KNM";
              mode = "1920x1080@60.00";
              position = "1920x0";
              scale = 1;
            }
            {
              # right, 180Hz
              output = "desc:25E3A 0000000000001";
              mode = "1920x1080@180.00";
              position = "3840x0";
              scale = 1;
            }
          ]
          else if hostConfig.name == "manus"
          then [
            {
              # left external
              output = "desc:LG ULTRAGEAR 0x0004A026";
              mode = "2560x1440@60.00";
              position = "0x1120";
              scale = 1;
            }
            {
              # right external, rotated
              output = "desc:LG ULTRAGEAR 406NTXR8X146";
              mode = "2560x1440@60.00";
              position = "4480x0";
              transform = 3; # rotate-270
              scale = 1;
            }
            {
              # laptop panel
              output = "desc:Lenovo Group Limited 0x4146";
              mode = "1920x1200@60.00";
              position = "2560x1360";
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
          {
            _args = [
              "myBezier"
              {
                type = "bezier";
                points = [[0.05 0.9] [0.1 1.05]];
              }
            ];
          }
        ];

        animation = [
          {
            leaf = "windows";
            enabled = true;
            speed = 7;
            bezier = "myBezier";
            style = slide;
          }
          {
            leaf = "windowsOut";
            enabled = true;
            speed = 7;
            bezier = "default";
            style = "popin 80%";
          }
          {
            leaf = "border";
            enabled = true;
            speed = 10;
            bezier = "default";
          }
          {
            leaf = "borderangle";
            enabled = true;
            speed = 8;
            bezier = "default";
          }
          {
            leaf = "fade";
            enabled = true;
            speed = 7;
            bezier = "default";
          }
          {
            leaf = "workspaces";
            enabled = true;
            speed = 6;
            bezier = "default";
            style = slide;
          }
        ];

        gesture = [
          {
            fingers = 3;
            direction = "horizontal";
            action = "workspace";
          }
          {
            fingers = 3;
            direction = "vertical";
            action = "move";
          }
        ];

        layer_rule = [
          {
            match = {namespace = "rofi";};
            blur = true;
          }
        ];

        window_rule = sharedRules;

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
                hl.exec_cmd("foot --app-id=iamb --title=iamb iamb")
              end'')
          ];
        };

        # The shared launchers and commands, then the hyprland side of jay's
        # own actions (jay/_config.nix), in the same keys.
        bind =
          sharedBinds
          ++ [
            # iamb and Signal open at login (hyprland.start below); these
            # focus their workspace and reopen them only if they were closed.
            (mkBind "SUPER + i" ''
              function()
                hl.dispatch(hl.dsp.focus({ workspace = 2 }))
                hl.exec_cmd("pgrep -x iamb >/dev/null || foot --app-id=iamb --title=iamb iamb")
              end'')
            (mkBind "SUPER + SHIFT + i" ''
              function()
                hl.dispatch(hl.dsp.focus({ workspace = 5 }))
                hl.exec_cmd("pgrep -x signal-desktop >/dev/null || signal-desktop")
              end'')

            # Keyboard layouts: kb_layout lists dvorak first, qwerty second.
            (mkBind "SUPER + backslash" ''hl.dsp.exec_cmd("hyprctl switchxkblayout all 1")'')
            (mkBind "SUPER + SHIFT + backslash" ''hl.dsp.exec_cmd("hyprctl switchxkblayout all 0")'')

            (mkBind "SUPER + SHIFT + q" ''hl.dsp.window.close()'')
            (mkBind "SUPER + CONTROL + SHIFT + semicolon" ''hl.dsp.exit()'')

            (mkBind "SUPER + space" ''hl.dsp.window.float({ action = "toggle" })'')
            (mkBind "SUPER + t" ''hl.dsp.layout("togglesplit")'')
            (mkBind "SUPER + f" ''hl.dsp.window.fullscreen({ mode = "maximized" })'')
            (mkBind "SUPER + SHIFT + f" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'')

            # Wallpaper and bar restart; jay refreshes its bar by reloading.
            (mkBind "SUPER + bracketleft" ''hl.dsp.exec_cmd("awww kill; awww-daemon && awww img ${wallpaper}")'')
            (mkBind "SUPER + bracketright" ''hl.dsp.exec_cmd("pkill waybar; sleep 0.5 && waybar")'')
            (mkBind "SUPER + SHIFT + r" ''hl.dsp.reload_config()'')
            (mkBind "SUPER + CONTROL + b" ''hl.dsp.exec_cmd("pkill -SIGUSR1 waybar")'')

            (mkBind "SUPER + o" ''hl.dsp.workspace.move({ monitor = "+1" })'')
            (mkBind "SUPER + SHIFT + o" ''hl.dsp.workspace.move({ monitor = "-1" })'')

            # Scroll through existing workspaces with mainMod + scroll
            (mkBind "SUPER + mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'')
            (mkBind "SUPER + mouse_up" ''hl.dsp.focus({ workspace = "e-1" })'')

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
