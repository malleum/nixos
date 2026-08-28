# The jay config document itself.
#
# Kept as a TOML string rather than generated with `(pkgs.formats.toml {})`
# on purpose: generated TOML drops comments, and the comments here carry the
# reasoning (why noretry is set the way it is, why the trailing bar blocks are
# background-coloured, which protocols are privileged). That reasoning is the
# most valuable thing in the file.
{
  pkgs,
  hostName,
  colors,
  wallpaper,
  browser,
  browser2,
  mod,
  leftMonitorSerial,
  jayStatus,
  jayLock,
  audioSwitch,
  monitorToggle,
  powerMenu,
  windowSwitch,
  osd,
}: let
  # Monitor config per host
  # NOTE: Run `jay randr` to discover serial numbers and connector names,
  # then replace the match fields below with your actual serial numbers
  # for stable identification across reboots.
  outputConfig =
    if hostName == "magnus"
    # toml
    then ''
      # Large TV (left) — serial "1" is non-unique, pair with manufacturer
      [[outputs]]
      match.serial-number = "1"
      match.manufacturer = "BBY"
      name = "left"
      x = 0
      y = 0
      mode = { width = 1920, height = 1080, refresh-rate = 60.0 }

      # HP V222vb (middle)
      [[outputs]]
      match.serial-number = "3CQ1261KNM"
      name = "middle"
      x = 1920
      y = 0
      mode = { width = 1920, height = 1080, refresh-rate = 60.0 }

      # HKC 25E3A (right, 180Hz)
      [[outputs]]
      match.serial-number = "0000000000001"
      name = "right"
      x = 3840
      y = 0
      mode = { width = 1920, height = 1080, refresh-rate = 180.0 }
    ''
    else if hostName == "manus"
    # toml
    then ''
      # LG ULTRAGEAR (left monitor) — connector floats between DP-1/DP-2,
      # so match on EDID serial instead.
      [[outputs]]
      match.serial-number = "${leftMonitorSerial}"
      name = "left"
      x = 0
      y = 1120
      mode = { width = 2560, height = 1440, refresh-rate = 60.0 }

      # LG ULTRAGEAR (right monitor, rotated)
      [[outputs]]
      match.serial-number = "406NTXR8X146"
      name = "right"
      x = 4480
      y = 0
      mode = { width = 2560, height = 1440, refresh-rate = 60.0 }
      transform = "rotate-270"

      # Lenovo laptop panel (right of the left external, or standalone).
      # Serial "0" is non-unique, so pair it with the manufacturer.
      [[outputs]]
      match.serial-number = "0"
      match.manufacturer = "LEN"
      name = "laptop"
      x = 2560
      y = 1360
      mode = { width = 1920, height = 1200, refresh-rate = 60.0 }
    ''
    # toml
    else ''
      # Fallback: let jay auto-detect
    '';

  jayConfig =
    # toml
    ''
      # ── General ──────────────────────────────────────────────────
      log-level = "info"
      focus-follows-mouse = true
      window-management-key = "Super_L"
      auto-reload = true
      show-titles = false
      workspace-display-order = "sorted"
      idle.minutes = 0

      # ── Keyboard ─────────────────────────────────────────────────
      keymap.name = "dvorak"
      repeat-rate = { rate = 100, delay = 200 }

      # ── Startup ──────────────────────────────────────────────────
      on-startup = [
        { type = "set-env", env = { XDG_CURRENT_DESKTOP = "jay" } },
      ]

      # Everything the session needs is a systemd user unit wanted by
      # jay-session.target (see systemd.user.services below), so starting the
      # target is the only thing that happens here. On magnus, the TV also
      # gets forced off here -- it's kept off most of the time, so it should
      # start off rather than in whatever state it was left in, with
      # super-shift-m toggling from there.
      on-graphics-initialized = [
        { type = "exec", exec = { shell = "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user start jay-session.target" } },
        ${
        if hostName == "magnus"
        then ''{ type = "exec", exec = ["${monitorToggle}/bin/jay-toggle-monitor", "${leftMonitorSerial}", "off"] },''
        else ""
      }
      ]

      # ── Keyboard layouts ─────────────────────────────────────────
      [[keymaps]]
      name = "dvorak"
      map = """
        xkb_keymap {
            xkb_keycodes { include "evdev" };
            xkb_types    { include "basic" };
            xkb_compat   { include "basic" };
            xkb_symbols  {
                include "pc+us(dvorak)+inet(evdev)"
                key <CAPS> { [ Escape ] };
                key <INS>  { [ Multi_key ] };
                key <COMP> { [ Multi_key ] };
                key <RALT> { [ Multi_key ] };
            };
        };
      """

      [[keymaps]]
      name = "qwerty"
      rmlvo = { layout = "us", options = "caps:escape,compose:ins,compose:ralt,esperanto:dvorak" }

      # ── Environment ──────────────────────────────────────────────
      [env]
      NIXOS_OZONE_WL = "1"
      GDK_BACKEND = "wayland,x11"
      LIBVA_DRIVER_NAME = "radeonsi"
      MOZ_ENABLE_WAYLAND = "1"
      MOZ_WEBRENDER = "1"
      MOZ_ACCELERATED = "1"
      XDG_CURRENT_DESKTOP = "jay"

      # ── Outputs ──────────────────────────────────────────────────
      ${outputConfig}

      # ── Input ────────────────────────────────────────────────────
      [[inputs]]
      match.is-pointer = true
      accel-profile = "Flat"
      accel-speed = 0.0
      natural-scrolling = false
      tap-enabled = true
      tap-drag-enabled = true

      [[inputs]]
      match.is-gesture = true
      natural-scrolling = true

      # ── Theme ─────────────────────────────────────────────────────
      [theme]
      # Only ever seen for the instant before swaybg comes up; matching base00
      # keeps that flash from being a black frame.
      bg-color = "#${colors.base00}"
      # Colors take #rrggbbaa. The bar is translucent to sit with the 0.85
      # terminals and 0.9 popups stylix sets, instead of reading heavier than
      # everything else on screen.
      bar-bg-color = "#${colors.base01}D9"
      bar-status-text-color = "#${colors.base05}"
      # Titles are hidden, so the border is the *only* focus indicator:
      # dim base02 between unfocused windows, accent ring on the focused one.
      # focused-border-color requires the `full` container border style --
      # with the default `separators` there is no border to recolor.
      border-color = "#${colors.base02}"
      focused-border-color = "#${colors.base0D}"
      container-borders = "full"
      # Workspace tabs (titles are hidden, so these only style the bar tabs):
      # active = accent pill w/ dark text; others = subtle pill w/ readable text.
      focused-title-bg-color = "#${colors.base0D}"
      focused-title-text-color = "#${colors.base00}"
      unfocused-title-bg-color = "#${colors.base02}"
      unfocused-title-text-color = "#${colors.base05}"
      focused-inactive-title-bg-color = "#${colors.base02}"
      focused-inactive-title-text-color = "#${colors.base05}"
      attention-requested-bg-color = "#${colors.base08}"
      separator-color = "#${colors.base02}"
      highlight-color = "#${colors.base0E}"
      border-width = 2
      title-height = 24
      bar-height = 32
      bar-separator-width = 4
      font = "JetBrainsMono Nerd Font 10"
      title-font = "JetBrainsMono Nerd Font 10"
      bar-font = "JetBrainsMono Nerd Font 13"
      bar-position = "top"

      # ── Status Bar ───────────────────────────────────────────────
      [status]
      format = "i3bar"
      # Each block draws its own rounded pill (see _status.nix), so the
      # separator is plain space -- a middot between pills reads as clutter.
      i3bar-separator = "  "
      exec = "${jayStatus}/bin/jay-status"

      # ── Named Actions ────────────────────────────────────────────
      [actions]
      launch-terminal = { type = "exec", exec = { shell = "$TERMINAL" } }
      launch-kitty = { type = "exec", exec = "kitty" }
      launch-browser = { type = "exec", exec = "${browser}" }
      launch-browser2 = { type = "exec", exec = "${browser2}" }
      launch-vesktop = { type = "exec", exec = "vesktop" }
      launch-teams = { type = "exec", exec = ["${browser}", "--new-window", "https://teams.microsoft.com/v2/"] }
      launch-calendar = { type = "exec", exec = ["${browser}", "--new-window", "https://calendar.google.com/calendar/r"] }

      # ── Shortcuts ────────────────────────────────────────────────
      [shortcuts]

      # ─ App launchers ─
      ${mod}-Return = "$launch-terminal"
      ${mod}-shift-Return = "$launch-kitty"
      ${mod}-b = "$launch-browser"
      ${mod}-shift-b = "$launch-browser2"
      ${mod}-d = "$launch-vesktop"
      ${mod}-shift-d = "$launch-teams"
      # iamb and signal are already running as jay-session login units
      # (see iamb.nix), so these just focus their workspace instead of
      # relaunching -- a plain $launch action spawned a duplicate process.
      ${mod}-i = [{ type = "show-workspace", name = "2" }, "warp-mouse-to-focus", { type = "exec", exec = { shell = "systemctl --user restart iamb.service" } } ]
      ${mod}-shift-i = [{ type = "show-workspace", name = "5" }, "warp-mouse-to-focus"]
      ${mod}-ctrl-c = "open-control-center"
      ${mod}-shift-c = "$launch-calendar"

      # ─ Clipboard copypaste ─
      ${mod}-x = { type = "exec", exec = { prog = "${pkgs.wl-clipboard}/bin/wl-copy", args = ["https://xkcd.com/1475/"], privileged = true } }
      ${mod}-shift-x = { type = "exec", exec = { prog = "${pkgs.wl-clipboard}/bin/wl-copy", args = ["Neida, jeg ville vinne"], privileged = true } }

      # ─ Notifications (swaync) ─
      ${mod}-n = { type = "exec", exec = ["swaync-client", "--close-all"] }
      ${mod}-shift-n = { type = "exec", exec = { shell = "swaync-client --dnd-off && notify-send 'Notifications Enabled' -t 1000" } }
      ${mod}-ctrl-n = { type = "exec", exec = { shell = "notify-send 'Notifications Disabled' -t 300; sleep 0.3; swaync-client --dnd-on" } }
      ${mod}-ctrl-shift-n = { type = "exec", exec = ["swaync-client", "-a", "0"] }

      # ─ App launcher (rofi) ─
      ${mod}-s = { type = "exec", exec = { shell = "rofi -show drun" } }

      # ─ Audio output switch (default + move all streams) ─
      ${mod}-ctrl-a = { type = "exec", exec = "${audioSwitch}/bin/jay-audio-switch" }

      # ─ Media control (MPRIS: browser tabs, spotify, vesktop) ─
      # Duplicates the XF86Audio* keys for keyboards that lack them.
      ${mod}-ctrl-p = { type = "exec", exec = ["${pkgs.playerctl}/bin/playerctl", "play-pause"] }
      ${mod}-ctrl-l = { type = "exec", exec = ["${pkgs.playerctl}/bin/playerctl", "next"] }
      ${mod}-ctrl-h = { type = "exec", exec = ["${pkgs.playerctl}/bin/playerctl", "previous"] }

      # ─ Network / bluetooth / audio pickers (all rofi-driven) ─
      ${mod}-w = { type = "exec", exec = ["${pkgs.iwmenu}/bin/iwmenu", "--launcher", "rofi"] }
      ${mod}-shift-w = { type = "exec", exec = ["${pkgs.bzmenu}/bin/bzmenu", "--launcher", "rofi"] }
      # Distinct app-id and title so the generic "foot -> workspace 3" rule
      # below does not catch it; the window rule floats it on whichever
      # workspace is active instead.
      ${mod}-ctrl-w = { type = "exec", exec = ["${pkgs.foot}/bin/foot", "--app-id=wiremix", "--title=wiremix", "${pkgs.wiremix}/bin/wiremix"] }

      # ─ Window switcher (all workspaces) ─
      ${mod}-Tab = { type = "exec", exec = "${windowSwitch}/bin/jay-window-switch" }

      # ─ Power menu ─
      ${mod}-ctrl-e = { type = "exec", exec = "${powerMenu}/bin/jay-power-menu" }

      # ─ Click anywhere from the keyboard ─
      ${mod}-g = { type = "exec", exec = { prog = "${pkgs.wl-kbptr}/bin/wl-kbptr", privileged = true } }

      # ─ Toggle left monitor on/off ─
      ${mod}-shift-m = { type = "exec", exec = ["${monitorToggle}/bin/jay-toggle-monitor", "${leftMonitorSerial}"] }

      # ─ Clipboard history ─
      ${mod}-v = { type = "exec", exec = { shell = "${pkgs.cliphist}/bin/cliphist list | rofi -theme-str 'window {width: 75%;}' -dmenu | ${pkgs.cliphist}/bin/cliphist decode | wl-copy", privileged = true } }

      # ─ Calculator (rofi-calc with live preview) ─
      ${mod}-c = { type = "exec", exec = { shell = "rofi -theme-str 'window {width: 75%;}' -show calc -modi calc -no-show-match -no-sort -qalc-binary qalc | wl-copy", privileged = true } }

      # ─ Emoji picker ─
      ${mod}-shift-e = { type = "exec", exec = { shell = "rofi -modi emoji -show emoji | wl-copy", privileged = true } }

      # ─ Keyboard layout switching ─
      ${mod}-backslash = { type = "set-keymap", map = { name = "qwerty" } }
      ${mod}-shift-backslash = { type = "set-keymap", map = { name = "dvorak" } }

      # ─ Window management ─
      ${mod}-shift-q = "close"
      ${mod}-ctrl-shift-semicolon = "quit"
      ${mod}-shift-z = { type = "exec", exec = "poweroff" }
      ${mod}-ctrl-z = { type = "exec", exec = "reboot" }

      # ─ Screenshots (jay screenshot + satty) ─
      Print = { type = "exec", exec = { shell = "jay screenshot /tmp/jay-screenshot.png && ${pkgs.wl-clipboard}/bin/wl-copy < /tmp/jay-screenshot.png", privileged = true } }
      shift-Print = { type = "exec", exec = { shell = "jay screenshot /tmp/jay-screenshot.png && ${pkgs.satty}/bin/satty -f /tmp/jay-screenshot.png", privileged = true } }
      ${mod}-shift-s = { type = "exec", exec = { shell = "${pkgs.hyprshot}/bin/hyprshot -m region --clipboard-only", privileged = true } }
      ${mod}-ctrl-s = { type = "exec", exec = { shell = "${pkgs.wl-clipboard}/bin/wl-paste | ${pkgs.satty}/bin/satty -f -", privileged = true } }

      # ─ Floating / layout ─
      ${mod}-a = ["focus-parent", "warp-mouse-to-focus"]
      ${mod}-space = "toggle-floating"
      ${mod}-t = "toggle-split"
      ${mod}-f = "toggle-mono"
      ${mod}-shift-f = "toggle-fullscreen"

      # ─ Screen lock ─
      # jay-lock is swaylock-effects with the theme's colors (see _lock.nix).
      # The binary it execs is still called swaylock, so the [[clients]] rule
      # granting session-lock below still matches it.
      ${mod}-BackSpace = { type = "exec", exec = { prog = "${jayLock}/bin/jay-lock", privileged = true } }

      # ─ Wallpaper restart ─
      ${mod}-bracketleft = { type = "exec", exec = { shell = "pkill swaybg; ${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill &" } }

      # ─ Bar refresh ─
      # There is no "restart the status" action: jay respawns the status command
      # when it re-reads the config, so reloading is the way to refresh the bar.
      # Nothing was bound to bracketright before, which is why super-] just
      # typed a ] into the focused window. Note these are *keysyms* on the
      # active (dvorak) keymap, so bracketleft/bracketright sit on the physical
      # keys qwerty calls - and =.
      ${mod}-bracketright = "reload-config-toml"

      # ─ Kill electron ─
      ${mod}-ctrl-d = { type = "exec", exec = { shell = "killall electron" } }
      ${mod}-ctrl-shift-d = { type = "exec", exec = { shell = "killall .electron-wrapp; killall electron" } }

      # ─ Move workspace to other output ─
      # No focus action here on purpose. move_ws_to_output (src/state.rs) does
      # not touch the keyboard focus, so after the move the focus is already on
      # this workspace on its new output. The `focus-right` that used to follow
      # was what broke it: focus-right resolves the workspace's output, which
      # by then *is* the target output, and steps one further -- on a 3-monitor
      # host, moving left->middle landed the focus on the right monitor.
      # Only the pointer needs to catch up.
      ${mod}-o = [{ type = "move-to-output", direction = "right" }, "warp-mouse-to-focus"]
      ${mod}-shift-o = [{ type = "move-to-output", direction = "left" }, "warp-mouse-to-focus"]

      # ─ Focus movement (vim-style) ─
      ${mod}-h = ["focus-left", "warp-mouse-to-focus"]
      ${mod}-j = ["focus-down", "warp-mouse-to-focus"]
      ${mod}-k = ["focus-up", "warp-mouse-to-focus"]
      ${mod}-l = ["focus-right", "warp-mouse-to-focus"]

      # ─ Move windows (vim-style) ─
      # move-left/right cross to the neighboring output when the window is at
      # the edge of the tree, and jay keeps the keyboard focus on the moved
      # window. But focus-follows-mouse is on and the pointer stays behind on
      # the old output, so the next pointer event handed focus back to whatever
      # was under it -- hence the warp, same as the focus bindings above.
      ${mod}-shift-h = ["move-left", "warp-mouse-to-focus"]
      ${mod}-shift-j = ["move-down", "warp-mouse-to-focus"]
      ${mod}-shift-k = ["move-up", "warp-mouse-to-focus"]
      ${mod}-shift-l = ["move-right", "warp-mouse-to-focus"]

      # ─ Workspaces (dvorak home row: ' , . p y) ─
      ${mod}-apostrophe = [{ type = "show-workspace", name = "1" }, "warp-mouse-to-focus"]
      ${mod}-comma = [{ type = "show-workspace", name = "2" }, "warp-mouse-to-focus"]
      ${mod}-period = [{ type = "show-workspace", name = "3" }, "warp-mouse-to-focus"]
      ${mod}-p = [{ type = "show-workspace", name = "4" }, "warp-mouse-to-focus"]
      ${mod}-y = [{ type = "show-workspace", name = "5" }, "warp-mouse-to-focus"]

      ${mod}-shift-apostrophe = [{ type = "move-to-workspace", name = "1" }, { type = "show-workspace", name = "1" }, "warp-mouse-to-focus"]
      ${mod}-shift-comma = [{ type = "move-to-workspace", name = "2" }, { type = "show-workspace", name = "2" }, "warp-mouse-to-focus"]
      ${mod}-shift-period = [{ type = "move-to-workspace", name = "3" }, { type = "show-workspace", name = "3" }, "warp-mouse-to-focus"]
      ${mod}-shift-p = [{ type = "move-to-workspace", name = "4" }, { type = "show-workspace", name = "4" }, "warp-mouse-to-focus"]
      ${mod}-shift-y = [{ type = "move-to-workspace", name = "5" }, { type = "show-workspace", name = "5" }, "warp-mouse-to-focus"]

      # ─ Reload config ─
      ${mod}-shift-r = "reload-config-toml"

      # ─ Toggle bar / titles ─
      ${mod}-ctrl-b = "toggle-bar"
      ${mod}-ctrl-t = "toggle-titles"

      # ─ VT switching (essential for recovery) ─
      ctrl-alt-F1 = { type = "switch-to-vt", num = 1 }
      ctrl-alt-F2 = { type = "switch-to-vt", num = 2 }
      ctrl-alt-F3 = { type = "switch-to-vt", num = 3 }
      ctrl-alt-F4 = { type = "switch-to-vt", num = 4 }
      ctrl-alt-F5 = { type = "switch-to-vt", num = 5 }
      ctrl-alt-F6 = { type = "switch-to-vt", num = 6 }
      ctrl-alt-F7 = { type = "switch-to-vt", num = 7 }
      ctrl-alt-F8 = { type = "switch-to-vt", num = 8 }
      ctrl-alt-F9 = { type = "switch-to-vt", num = 9 }
      ctrl-alt-F10 = { type = "switch-to-vt", num = 10 }
      ctrl-alt-F11 = { type = "switch-to-vt", num = 11 }
      ctrl-alt-F12 = { type = "switch-to-vt", num = 12 }

      # ── Complex Shortcuts (media keys regardless of modifiers) ──
      # jay-osd wraps swayosd-client, pinning the popup to the focused output.
      # swayosd-client both performs the change and draws the on-screen
      # indicator, so these stay one action. It talks to swayosd-server,
      # which runs as a jay-session unit.
      [complex-shortcuts.XF86AudioLowerVolume]
      mod-mask = ""
      action = { type = "exec", exec = ["${osd}/bin/jay-osd", "--output-volume", "lower"] }

      [complex-shortcuts.XF86AudioRaiseVolume]
      mod-mask = ""
      action = { type = "exec", exec = ["${osd}/bin/jay-osd", "--output-volume", "raise", "--max-volume", "150"] }

      [complex-shortcuts.XF86AudioMute]
      mod-mask = ""
      action = { type = "exec", exec = ["${osd}/bin/jay-osd", "--output-volume", "mute-toggle"] }

      [complex-shortcuts.XF86AudioMicMute]
      mod-mask = ""
      action = { type = "exec", exec = ["${osd}/bin/jay-osd", "--input-volume", "mute-toggle"] }

      # Media keys: playerctl drives whatever holds the MPRIS bus, which
      # includes Firefox/Brave tabs, Spotify and vesktop.
      [complex-shortcuts.XF86AudioPlay]
      mod-mask = ""
      action = { type = "exec", exec = ["${pkgs.playerctl}/bin/playerctl", "play-pause"] }

      [complex-shortcuts.XF86AudioNext]
      mod-mask = ""
      action = { type = "exec", exec = ["${pkgs.playerctl}/bin/playerctl", "next"] }

      [complex-shortcuts.XF86AudioPrev]
      mod-mask = ""
      action = { type = "exec", exec = ["${pkgs.playerctl}/bin/playerctl", "previous"] }

      [complex-shortcuts.XF86AudioStop]
      mod-mask = ""
      action = { type = "exec", exec = ["${pkgs.playerctl}/bin/playerctl", "stop"] }

      [complex-shortcuts.XF86MonBrightnessUp]
      mod-mask = ""
      action = { type = "exec", exec = ["${osd}/bin/jay-osd", "--brightness", "raise"] }

      [complex-shortcuts.XF86MonBrightnessDown]
      mod-mask = ""
      action = { type = "exec", exec = ["${osd}/bin/jay-osd", "--brightness", "lower"] }

      # ── Window Rules ─────────────────────────────────────────────

      # Workspace assignments
      [[windows]]
      match.title-regex = ".*Microsoft Teams.*"
      action = { type = "move-to-workspace", name = "2" }

      [[windows]]
      match.title-regex = ".*Brave.*"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "1" }

      [[windows]]
      match.title-regex = ".*Firefox.*"
      match.not.title-regex = ".*Microsoft Teams.*"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "1" }

      [[windows]]
      match.title-regex = ".*Ninjabrain Bot.*"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "1" }

      [[windows]]
      match.title-regex = ".*e4mc.*"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "1" }

      # Matched on app-id, set by the launcher, so this fires at map time.
      # Matching the title instead meant foot's placeholder title ("foot") hit
      # the foot -> workspace 3 rule below first, and the window only moved to
      # 2 once iamb got around to setting its own title.
      [[windows]]
      match.app-id = "iamb"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "2" }

      [[windows]]
      match.title = "kitty"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "3" }

      [[windows]]
      match.title = "foot"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "3" }

      [[windows]]
      match.title-regex = ".*(Steam|Minecraft|Prism Launcher|Terraria|War|resident|Resident).*"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "4" }

      [[windows]]
      match.title-regex = ".*OBS.*"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "5" }

      [[windows]]
      match.title-regex = ".*MainPicker.*"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "5" }

      [[windows]]
      match.title = "Signal"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "5" }

      [[windows]]
      match.title-regex = ".*Discord.*"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "5" }

      [[windows]]
      match.title-regex = ".*Element.*"
      match.just-mapped = true
      action = { type = "move-to-workspace", name = "2" }

      # Float file dialogs
      [[windows]]
      match.title-regex = ".*(All|Save) Files?.*"
      initial-tile-state = "floating"

      # Float pavucontrol
      [[windows]]
      match.app-id = "pavucontrol"
      initial-tile-state = "floating"

      # Float nm-connection-editor
      [[windows]]
      match.app-id = "nm-connection-editor"
      initial-tile-state = "floating"

      # Float satty
      [[windows]]
      match.app-id = "com.gabm.satty"
      initial-tile-state = "floating"

      # Float the polkit password prompt
      [[windows]]
      match.app-id = "polkit-gnome-authentication-agent-1"
      initial-tile-state = "floating"

      # Float the audio mixers. No move-to-workspace rule, so they open
      # floating on whatever workspace is active.
      [[windows]]
      match.app-id = "com.saivert.pwvucontrol"
      initial-tile-state = "floating"

      [[windows]]
      match.app-id = "wiremix"
      initial-tile-state = "floating"

      # ── Client Rules (grant privileged protocol access) ─────────
      [[clients]]
      match.any = [
        { comm = "wl-copy" },
        { comm = ".wl-copy-wrappe" },
        { comm = "wl-paste" },
        { comm = ".wl-paste-wrapp" },
        { comm = "cliphist" },
        { comm = "iamb" },
        { comm = "foot" },
        { comm = "kitty" },
        { comm = "tmux" },
        { comm = "nvim" },
        { comm = ".nvim-wrapped" },
      ]
      capabilities = ["data-control"]

      [[clients]]
      match.comm = "satty"
      capabilities = ["layer-shell"]

      [[clients]]
      match.comm = "swaylock"
      capabilities = ["session-lock", "layer-shell"]

      [[clients]]
      match.any = [
        { comm = "swaync" },
        { comm = "swaync-client" },
      ]
      capabilities = ["layer-shell"]

      [[clients]]
      match.comm = "nm-applet"
      capabilities = ["layer-shell"]

      [[clients]]
      match.comm = "rofi"
      capabilities = ["layer-shell"]

      [[clients]]
      match.comm = "swayosd-server"
      capabilities = ["layer-shell"]

      # wl-kbptr paints its key hints as an overlay and warps the pointer.
      [[clients]]
      match.comm = "wl-kbptr"
      capabilities = ["layer-shell", "virtual-pointer"]

      # Screen-capture tools. jay hides wlr-screencopy from unprivileged
      # clients, so these work from a keybinding (which passes
      # privileged = true) but silently fail when launched from a shell.
      [[clients]]
      match.any = [
        { comm = "hyprpicker" },
        { comm = "grim" },
        { comm = "hyprshot" },
        { comm = "wf-recorder" },
      ]
      capabilities = ["screencopy"]

      # Output layout (wlr-output-management) and window control
      # (wlr-foreign-toplevel) are likewise privileged.
      [[clients]]
      match.comm = "wdisplays"
      capabilities = ["head-manager"]

      [[clients]]
      match.comm = "wlrctl"
      capabilities = ["foreign-toplevel-manager"]

      # ── Xwayland ─────────────────────────────────────────────────
      [xwayland]
      enabled = true
    '';
in
  jayConfig
