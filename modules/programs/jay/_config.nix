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
  # "firefox-work" on wrk hosts (see firefox.nix), null elsewhere.
  workBrowser,
  # The wrk-primary tag: work Firefox takes mod+b, personal Firefox moves to
  # mod+shift-b and workspace 5, and Brave loses its key.
  workPrimary,
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
  inherit (pkgs) lib;

  # Launchers, commands and window rules shared with hyprland.
  desktop = import ../_desktop.nix {
    inherit pkgs lib hostName browser browser2 workBrowser workPrimary windowSwitch audioSwitch osd;
    compositor = "jay";
    lock = jayLock;
  };
  # JSON strings and string arrays are valid TOML.
  toml = builtins.toJSON;
  exec = b: let
    priv = lib.optionalString (b.privileged or false) ", privileged = true";
  in
    if b ? sh
    then ''{ type = "exec", exec = { shell = ${toml b.sh}${priv} } }''
    else ''{ type = "exec", exec = { prog = ${toml (lib.head b.argv)}, args = ${toml (lib.tail b.argv)}${priv} } }'';
  anyMods = b: b.anyMods or false;
  sharedShortcuts = lib.concatMapStrings (b: "${lib.replaceStrings ["MOD-"] ["${mod}-"] b.key} = ${exec b}\n") (lib.filter (b: !anyMods b) desktop.binds);
  sharedComplex = lib.concatMapStrings (b: ''

    [complex-shortcuts.${b.key}]
    mod-mask = ""
    action = ${exec b}
  '') (lib.filter anyMods desktop.binds);
  sharedRules = lib.concatMapStrings (r: let
    m = r.match;
    line = cond: text: lib.optionalString cond "${text}\n";
  in
    "\n[[windows]]\n"
    + line (m ? title) "match.title-regex = ${toml (m.title or "")}"
    + line (m ? titleExact) "match.title = ${toml (m.titleExact or "")}"
    + line (m ? appId) "match.app-id = ${toml (m.appId or "")}"
    + line (m ? appIdRegex) "match.any = [{ app-id-regex = ${toml (m.appIdRegex or "")} }, { x-class-regex = ${toml (m.appIdRegex or "")} }]"
    + line (m ? notTitle) "match.not.title-regex = ${toml (m.notTitle or "")}"
    + line (r ? workspace && (r.justMapped or true)) "match.just-mapped = true"
    + line (r ? workspace) ''action = { type = "move-to-workspace", name = ${toml (r.workspace or "")} }''
    + line (r.float or false) ''initial-tile-state = "floating"'')
  desktop.rules;

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
        { type = "exec", exec = { shell = "rm -rf \"$XDG_RUNTIME_DIR/jay-session-apps\" && systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user start jay-session.target" } },
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

      # ── Shortcuts ────────────────────────────────────────────────
      # The launchers and commands shared with hyprland come from
      # ../_desktop.nix; the jay-only actions follow them.
      [shortcuts]
      ${sharedShortcuts}
      # ─ Workspace apps / control center ─
      # iamb and signal are already running as jay-session login units
      # (see iamb.nix), so these just focus their workspace instead of
      # relaunching -- a plain $launch action spawned a duplicate process.
      # iamb is `once`-stamped, so pressing this after quitting it is the one
      # place that clears the stamp: an explicit reopen, unlike the implicit
      # one a switch used to do. `start`, not `restart`, so a running iamb is
      # left alone instead of being killed and resynced.
      ${mod}-i = [{ type = "show-workspace", name = "2" }, "warp-mouse-to-focus", { type = "exec", exec = { shell = "rm -f \"$XDG_RUNTIME_DIR/jay-session-apps/iamb\"; systemctl --user start iamb.service" } } ]
      ${mod}-shift-i = [{ type = "show-workspace", name = "5" }, "warp-mouse-to-focus"]
      ${mod}-ctrl-c = "open-control-center"

      # ─ Power menu ─
      ${mod}-ctrl-e = { type = "exec", exec = "${powerMenu}/bin/jay-power-menu" }

      # ─ Toggle left monitor on/off ─
      ${mod}-shift-m = { type = "exec", exec = ["${monitorToggle}/bin/jay-toggle-monitor", "${leftMonitorSerial}"] }

      # ─ Keyboard layout switching ─
      ${mod}-backslash = { type = "set-keymap", map = { name = "qwerty" } }
      ${mod}-shift-backslash = { type = "set-keymap", map = { name = "dvorak" } }

      # ─ Window management ─
      ${mod}-shift-q = "close"
      ${mod}-ctrl-shift-semicolon = "quit"

      # ─ Floating / layout ─
      ${mod}-a = ["focus-parent", "warp-mouse-to-focus"]
      ${mod}-space = "toggle-floating"
      ${mod}-t = "toggle-split"
      ${mod}-f = "toggle-mono"
      ${mod}-shift-f = "toggle-fullscreen"

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
      ${sharedComplex}

      # ── Window Rules (../_desktop.nix) ───────────────────────────
      ${sharedRules}

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
        { comm = "teno" },
        { comm = "nvim" },
        { comm = ".nvim-wrapped" },
        { comm = ".vorto-wrapped" },
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
