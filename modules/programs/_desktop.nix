# Keybinds and window rules shared by jay (jay/_config.nix) and hyprland
# (hypr.nix). Each compositor imports this with its own `compositor` and
# renders the two lists into its own syntax; anything that only one of them
# can do (focus/move/workspace actions, layout, outputs, jay's privileged
# protocols) stays in that compositor's file.
#
# binds: { key; sh | argv; privileged?; anyMods?; }
#   key        jay spelling: modifiers then a keysym, `MOD` for the main
#              modifier ("MOD-shift-b", "shift-Print", "XF86AudioMute").
#              Hyprland matches keysyms case-insensitively, so the same names
#              work there.
#   sh / argv  a shell command line, or a program and its arguments.
#   privileged jay only: hand the program jay's privileged protocols
#              (clipboard, screencopy, virtual pointer).
#   anyMods    fire whatever modifiers are held (jay complex-shortcuts).
#
# rules: { match; workspace? | float?; justMapped?; }
#   match.title       regex on the title (written as a full match, ".*X.*")
#   match.titleExact  exact title (plain text, no regex characters)
#   match.appId       exact app-id (Wayland) / class (hyprland)
#   match.appIdRegex  regex on the app-id, or the X class under XWayland
#   match.notTitle    jay only: skip windows whose title matches this regex
#   justMapped        jay only, default true for workspace rules: apply when
#                     the window first maps, not whenever the match turns true.
{
  pkgs,
  lib,
  compositor, # "jay" or "hyprland"
  hostName,
  browser,
  browser2,
  # "firefox-work" on wrk hosts (see firefox.nix), null elsewhere.
  workBrowser,
  # The wrk-primary tag (work.primary).
  workPrimary,
  # The themed swaylock (jay/_lock.nix); it locks either compositor.
  lock,
  windowSwitch,
  audioSwitch,
  # jay-osd (jay only).
  osd ? null,
}: let
  jay = compositor == "jay";
  hasWork = workBrowser != null;
  # On the primary work machine work Firefox takes MOD+b, personal Firefox
  # moves to MOD+shift+b and workspace 5, and Brave loses its key.
  primary = workPrimary && hasWork;

  playerctl = "${pkgs.playerctl}/bin/playerctl";
  wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
  wide = "rofi -theme-str 'window {width: 75%;}'";

  # jay's media keys go through jay-osd (swayosd pinned to the focused output,
  # which needs jay's tree). swayosd-server only runs in the jay session, so
  # hyprland changes the values directly, without a popup.
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  media = jayArgs: hyprSh:
    if jay
    then {argv = ["${osd}/bin/jay-osd"] ++ jayArgs;}
    else {sh = hyprSh;};

  # magnus logs out, then suspends, so it wakes to the greeter. The suspend is
  # a transient timer in PID 1 because quitting the compositor kills this
  # shell and ends the session; a plain `systemctl suspend` afterwards would
  # no longer come from an active session, which polkit refuses. sudo is
  # passwordless for wheel (modules/system/security.nix).
  quit =
    if jay
    then "jay quit"
    else "hyprctl dispatch exit";
  shutdown =
    if hostName == "magnus"
    then "/run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemd-run --on-active=3 --timer-property=AccuracySec=100ms ${pkgs.systemd}/bin/systemctl suspend && ${quit}"
    else "poweroff";

  # Full-screen shots: jay has its own screenshot command, hyprland uses grim.
  satty = "${pkgs.satty}/bin/satty";
  shot = jayThen: grimTo:
    if jay
    then "jay screenshot /tmp/jay-screenshot.png && ${jayThen}"
    else "${pkgs.grim}/bin/grim - | ${grimTo}";
in {
  binds =
    [
      # ─ App launchers ─
      {
        key = "MOD-Return";
        sh = "$TERMINAL";
      }
      {
        key = "MOD-shift-Return";
        argv = ["kitty"];
      }
    ]
    ++ (
      if primary
      then [
        {
          key = "MOD-b";
          argv = [workBrowser];
        }
        {
          key = "MOD-shift-b";
          argv = [browser];
        }
      ]
      else
        [
          {
            key = "MOD-b";
            argv = [browser];
          }
          {
            key = "MOD-shift-b";
            argv = [browser2];
          }
        ]
        ++ lib.optional hasWork {
          key = "MOD-ctrl-shift-b";
          argv = [workBrowser];
        }
    )
    ++ [
      {
        key = "MOD-d";
        argv = ["vesktop"];
      }
    ]
    # Teams lives in the work profile; hosts without one get no key.
    ++ lib.optional hasWork {
      key = "MOD-shift-d";
      argv = [workBrowser "--new-window" "https://teams.microsoft.com/v2/"];
    }
    ++ [
      {
        key = "MOD-shift-c";
        argv = [browser "--new-window" "https://calendar.google.com/calendar/r"];
      }

      # ─ Clipboard copypaste ─
      {
        key = "MOD-x";
        argv = [wlCopy "https://xkcd.com/1475/"];
        privileged = true;
      }
      {
        key = "MOD-shift-x";
        argv = [wlCopy "Neida, jeg ville vinne"];
        privileged = true;
      }

      # ─ Notifications (swaync) ─
      {
        key = "MOD-n";
        argv = ["swaync-client" "--close-all"];
      }
      {
        key = "MOD-shift-n";
        sh = "swaync-client --dnd-off && notify-send 'Notifications Enabled' -t 1000";
      }
      {
        key = "MOD-ctrl-n";
        sh = "notify-send 'Notifications Disabled' -t 300; sleep 0.3; swaync-client --dnd-on";
      }
      {
        key = "MOD-ctrl-shift-n";
        argv = ["swaync-client" "-a" "0"];
      }

      # ─ rofi: apps, calculator, emoji, clipboard history, Esperanto ─
      {
        key = "MOD-s";
        sh = "rofi -show drun";
      }
      {
        key = "MOD-c";
        sh = "${wide} -show calc -modi calc -no-show-match -no-sort -qalc-binary qalc | wl-copy";
        privileged = true;
      }
      {
        key = "MOD-shift-e";
        sh = "rofi -modi emoji -show emoji | wl-copy";
        privileged = true;
      }
      {
        key = "MOD-v";
        sh = "${pkgs.cliphist}/bin/cliphist list | ${wide} -dmenu | ${pkgs.cliphist}/bin/cliphist decode | wl-copy";
        privileged = true;
      }
      {
        key = "MOD-shift-t";
        argv = ["eo-translate"];
        privileged = true;
      }

      # ─ Audio output switch (default + move all streams) ─
      {
        key = "MOD-ctrl-a";
        argv = ["${audioSwitch}/bin/jay-audio-switch"];
      }

      # ─ Media control (MPRIS: browser tabs, spotify, vesktop) ─
      # Duplicates the XF86Audio* keys for keyboards that lack them.
      {
        key = "MOD-ctrl-p";
        argv = [playerctl "play-pause"];
      }
      {
        key = "MOD-ctrl-l";
        argv = [playerctl "next"];
      }
      {
        key = "MOD-ctrl-h";
        argv = [playerctl "previous"];
      }

      # ─ Network / bluetooth / audio pickers (all rofi-driven) ─
      {
        key = "MOD-w";
        argv = ["${pkgs.iwmenu}/bin/iwmenu" "--launcher" "rofi"];
      }
      {
        key = "MOD-shift-w";
        argv = ["${pkgs.bzmenu}/bin/bzmenu" "--launcher" "rofi"];
      }
      # Distinct app-id and title so the "foot -> workspace 3" rule below
      # does not catch it; the float rule opens it on the active workspace.
      {
        key = "MOD-ctrl-w";
        argv = ["${pkgs.foot}/bin/foot" "--app-id=wiremix" "--title=wiremix" "${pkgs.wiremix}/bin/wiremix"];
      }

      # ─ Window switcher (all workspaces, over wlr-foreign-toplevel) ─
      {
        key = "MOD-Tab";
        argv = ["${windowSwitch}/bin/jay-window-switch"];
      }

      # ─ Click anywhere from the keyboard ─
      {
        key = "MOD-g";
        argv = ["${pkgs.wl-kbptr}/bin/wl-kbptr"];
        privileged = true;
      }

      # ─ Power ─
      {
        key = "MOD-shift-z";
        sh = shutdown;
        privileged = true;
      }
      {
        key = "MOD-ctrl-z";
        argv = ["reboot"];
      }

      # ─ Screen lock ─
      {
        key = "MOD-BackSpace";
        argv = ["${lock}/bin/jay-lock"];
        privileged = true;
      }

      # ─ Screenshots ─
      {
        key = "Print";
        sh = shot "${wlCopy} < /tmp/jay-screenshot.png" wlCopy;
        privileged = true;
      }
      {
        key = "shift-Print";
        sh = shot "${satty} -f /tmp/jay-screenshot.png" "${satty} -f -";
        privileged = true;
      }
      {
        key = "MOD-shift-s";
        sh = "${pkgs.hyprshot}/bin/hyprshot -m region --clipboard-only";
        privileged = true;
      }
      {
        key = "MOD-ctrl-s";
        sh = "${pkgs.wl-clipboard}/bin/wl-paste | ${pkgs.satty}/bin/satty -f -";
        privileged = true;
      }

      # ─ Kill electron ─
      {
        key = "MOD-ctrl-d";
        sh = "killall electron";
      }
      {
        key = "MOD-ctrl-shift-d";
        sh = "killall .electron-wrapp; killall electron";
      }

      # ─ Media keys, whatever modifiers are held ─
      (media ["--output-volume" "lower"] "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        // {
          key = "XF86AudioLowerVolume";
          anyMods = true;
        })
      (media ["--output-volume" "raise" "--max-volume" "150"] "${wpctl} set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
        // {
          key = "XF86AudioRaiseVolume";
          anyMods = true;
        })
      (media ["--output-volume" "mute-toggle"] "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"
        // {
          key = "XF86AudioMute";
          anyMods = true;
        })
      (media ["--input-volume" "mute-toggle"] "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        // {
          key = "XF86AudioMicMute";
          anyMods = true;
        })
      (media ["--brightness" "raise"] "${brightnessctl} set 10%+"
        // {
          key = "XF86MonBrightnessUp";
          anyMods = true;
        })
      (media ["--brightness" "lower"] "${brightnessctl} set 10%-"
        // {
          key = "XF86MonBrightnessDown";
          anyMods = true;
        })
    ]
    # playerctl drives whatever holds the MPRIS bus, which includes
    # Firefox/Brave tabs, Spotify and vesktop.
    ++ lib.mapAttrsToList (key: cmd: {
      inherit key;
      argv = [playerctl cmd];
      anyMods = true;
    }) {
      XF86AudioPlay = "play-pause";
      XF86AudioNext = "next";
      XF86AudioPrev = "previous";
      XF86AudioStop = "stop";
    };

  rules = let
    to = workspace: match: {inherit match workspace;};
    float = match: {
      inherit match;
      float = true;
    };
  in
    [
      # Teams sets its title after mapping, so this one follows the title.
      (to "2" {title = ".*Microsoft Teams.*";} // {justMapped = false;})
      (to "1" {title = ".*Brave.*";})
    ]
    # Personal Firefox (app-id `firefox`) gets workspace 5 on the primary work
    # machine; work Firefox (`firefox-work`) keeps 1. Every matching rule
    # fires, so the matches must not overlap.
    ++ (
      if primary
      then [
        (to "1" {
          appId = workBrowser;
          notTitle = ".*Microsoft Teams.*";
        })
        (to "5" {appId = "firefox";})
      ]
      else [
        (to "1" {
          title = ".*Firefox.*";
          notTitle = ".*Microsoft Teams.*";
        })
      ]
    )
    ++ [
      # The app-id is there before the first frame; the title is not (it
      # turns into the playing track).
      (to "5" {appIdRegex = "(?i)^spotify$";})
      (to "1" {title = ".*Ninjabrain Bot.*";})
      (to "1" {title = ".*e4mc.*";})
      # The launcher sets the app-id, so this fires at map time. Matching the
      # title instead meant foot's placeholder title ("foot") hit the foot ->
      # workspace 3 rule first.
      (to "2" {appId = "iamb";})
      (to "2" {title = ".*Element.*";})
      (to "3" {titleExact = "kitty";})
      (to "3" {titleExact = "foot";})
      (to "4" {title = ".*(Steam|Minecraft|Prism Launcher|Terraria|War|resident|Resident|Pipedream).*";})
      (to "5" {title = ".*OBS.*";})
      (to "5" {title = ".*MainPicker.*";})
      (to "5" {titleExact = "Signal";})
      (to "5" {title = ".*Discord.*";})

      # Dialogs and small tools float on whatever workspace is active.
      (float {title = ".*(All|Save) Files?.*";})
      (float {appId = "pavucontrol";})
      (float {appId = "nm-connection-editor";})
      (float {appId = "com.gabm.satty";})
      (float {appId = "polkit-gnome-authentication-agent-1";})
      (float {appId = "com.saivert.pwvucontrol";})
      (float {appId = "wiremix";})
    ];
}
