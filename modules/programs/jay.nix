{inputs, ...}: let
  makeJayPkg = pkgs:
    inputs.jay.packages.${pkgs.stdenv.hostPlatform.system}.jay.overrideAttrs (old: {
      RUSTC_BOOTSTRAP = "1";
      postPatch =
        (old.postPatch or "")
        + ''
          sed -i '1i #![feature(cfg_select)]' src/main.rs
        '';
    });
in {
  # Install jay.desktop to system-level wayland-sessions so ly can find it
  unify.modules.gui.nixos = {pkgs, ...}: {
    environment.systemPackages = [(makeJayPkg pkgs)];
    # Register jay.desktop with the display manager (ly, gdm, etc.)
    services.displayManager.sessionPackages = [(makeJayPkg pkgs)];
  };

  unify.modules.gui.home = {
    config,
    hostConfig,
    pkgs,
    ...
  }: let
    wallpaper = config.stylix.image;
    browser = hostConfig.user.browser;
    mod = "logo";

    jayPkg = makeJayPkg pkgs;

    # config.so: extends TOML config with smart workspace behaviors
    jayConfigSo = let
      configSrc = ./jay-config-so;
    in
      pkgs.rustPlatform.buildRustPackage {
        pname = "jay-config-so";
        version = "0.1.0";
        src = configSrc;
        cargoDeps = pkgs.rustPlatform.importCargoLock {
          lockFile = "${configSrc}/Cargo.lock";
        };

        # Patch vendored jay-toml-config to remove its config!() macro call
        # (causes duplicate JAY_CONFIG_ENTRY_V1 symbol otherwise).
        preBuild = ''
          toml_lib=$(find /build/cargo-vendor-dir -path '*/jay-toml-config-*/src/lib.rs' -print -quit 2>/dev/null)
          if [ -n "$toml_lib" ]; then
            sed -i '/^config!(configure);$/d' "$toml_lib"
          fi
        '';

        installPhase = ''
          mkdir -p $out/lib
          cp target/*/release/libjay_config_so.so $out/lib/config.so
        '';
      };

    wlTrayBridge = let
      src = pkgs.fetchFromGitHub {
        owner = "mahkoh";
        repo = "wl-tray-bridge";
        rev = "04cb349720f266917b5490e4a02f08d6ddf3f233";
        hash = "sha256-pYmFEqMMEsSTYBwxbD2l2F+lO7WuVt1FFmnkCCoaXf0=";
      };
    in
      pkgs.rustPlatform.buildRustPackage {
        pname = "wl-tray-bridge";
        version = "0-unstable-2025-04-01";
        inherit src;
        cargoDeps = pkgs.rustPlatform.importCargoLock {lockFile = "${src}/Cargo.lock";};
        nativeBuildInputs = with pkgs; [pkg-config autoPatchelfHook];
        buildInputs = with pkgs; [pango cairo glib wayland];
        runtimeDependencies = with pkgs; [wayland];
      };

    # Jay status bar script using i3bar JSON protocol
    # Reads from /proc and /sys directly where possible to minimize subprocess spawning.
    # Audio updates instantly via pactl subscribe; everything else updates every ~2s.
    # bash
    jayStatusScript = pkgs.writeShellScriptBin "jay-status" ''
      # Kill older instances (--older-than skips self, age <1s)
      ${pkgs.psmisc}/bin/killall -q -9 --older-than 1s jay-status 2>/dev/null || true

      echo '{"version":1}'
      echo '['
      echo '[]'

      # FIFO-based audio wakeup.
      # O_RDWR (<>) makes reads non-blocking on Linux — use separate O_RDONLY/O_WRONLY fds.
      # Open order: subscriber stdout->FIFO (child blocks on O_WRONLY), then parent opens
      # O_RDONLY (they "meet", both unblock). Parent then opens sentinel O_WRONLY (fd8) so
      # reads don't get EOF if pactl dies.
      audio_pipe=$(mktemp -u /tmp/jay-audio-XXXXXX)
      mkfifo "$audio_pipe"
      ( ${pkgs.pulseaudio}/bin/pactl subscribe 2>/dev/null | while IFS= read -r evt; do
          case "$evt" in *" sink "*|*" source "*) echo x ;; esac
        done ) >"$audio_pipe" &
      pactl_pid=$!
      exec 9<"$audio_pipe"   # O_RDONLY — blocks until subscriber opens write end (they meet)
      exec 8>"$audio_pipe"   # O_WRONLY sentinel — won't block (fd9 is now open reader)
      trap "kill $pactl_pid 2>/dev/null; wait $pactl_pid 2>/dev/null; exec 8>&-; exec 9>&-; rm -f $audio_pipe" EXIT HUP INT TERM

      # Block up to 2s; return instantly on audio event
      wait_tick() {
        local _d
        read -t 2 -r _d <&9 || true
        while read -t 0.01 -r _d <&9; do :; done || true  # drain extras (read -t 0 only polls, doesn't consume)
      }

      while true; do
        pieces=()

        # Audio (pulseaudio) — two quick pulsemixer calls with timeout
        vol=$(timeout 1 ${pkgs.pulsemixer}/bin/pulsemixer --get-volume 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $1}')
        mute=$(timeout 1 ${pkgs.pulsemixer}/bin/pulsemixer --get-mute 2>/dev/null)
        if [ "$mute" = "1" ]; then
          pieces+=("{\"name\":\"pulseaudio\",\"full_text\":\"audio: muted 󰝟\"}")
        else
          icon=""
          [ "''${vol:-0}" -gt 50 ] 2>/dev/null && icon=""
          [ "''${vol:-0}" -gt 75 ] 2>/dev/null && icon=""
          pieces+=("{\"name\":\"pulseaudio\",\"full_text\":\"audio ''${vol:-?}% $icon\"}")
        fi

        # CPU — read /proc/stat directly (no subprocesses)
        read -r _ u1 n1 s1 i1 _ < /proc/stat
        sleep 0.2
        read -r _ u2 n2 s2 i2 _ < /proc/stat
        total=$(( (u2+n2+s2+i2) - (u1+n1+s1+i1) ))
        idle=$(( i2 - i1 ))
        if [ "$total" -gt 0 ]; then
          cpu=$(( (total - idle) * 100 / total ))
        else
          cpu=0
        fi
        pieces+=("{\"name\":\"cpu\",\"full_text\":\"cpu $(printf '%02d' $cpu)% 󰍛\"}")

        # Memory — read /proc/meminfo directly (no subprocesses)
        while IFS=': ' read -r key val _; do
          case "$key" in
            MemTotal) mem_total=$val ;;
            MemAvailable) mem_avail=$val ;;
          esac
        done < /proc/meminfo
        if [ -n "$mem_total" ] && [ -n "$mem_avail" ]; then
          mem_used_kb=$(( mem_total - mem_avail ))
          mem_used_mb=$(( mem_used_kb / 1024 ))
          mem_gb=$(( mem_used_mb / 1024 ))
          mem_frac=$(( (mem_used_mb % 1024) * 10 / 1024 ))
          pieces+=("{\"name\":\"memory\",\"full_text\":\"mem $mem_gb.$mem_frac G 󰾅\"}")
        else
          pieces+=("{\"name\":\"memory\",\"full_text\":\"mem ?G 󰾅\"}")
        fi

        # Disk — one df call
        disk_pct=$(df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9')
        pieces+=("{\"name\":\"disk\",\"full_text\":\"disk $(printf '%02d' "''${disk_pct:-0}")% 󰋊\"}")

        # Battery (only if battery exists) — read /sys directly
        if [ -d /sys/class/power_supply/BAT0 ]; then
          bat_cap=$(< /sys/class/power_supply/BAT0/capacity)
          bat_status=$(< /sys/class/power_supply/BAT0/status)
          if [ "$bat_status" = "Charging" ] || [ "$bat_status" = "Full" ]; then
            bat_icon="󰂄"
          else
            bat_icon="󰁹"
          fi
          bat_json="{\"name\":\"battery\",\"full_text\":\"bat ''${bat_cap:-?}% $bat_icon\""
          if [ "''${bat_cap:-100}" -le 10 ] && [ "$bat_status" = "Discharging" ]; then
            bat_json="$bat_json,\"urgent\":true"
          fi
          bat_json="$bat_json}"
          pieces+=("$bat_json")
        fi

        # Date
        date_str=$(date '+%m-%d')
        pieces+=("{\"name\":\"clock\",\"full_text\":\"date $date_str 󰸗\"}")

        # Duodo clock — timeout to prevent hangs
        duod_val=$(timeout 1 duod 2>/dev/null | ${pkgs.choose}/bin/choose -c 0..4)
        pieces+=("{\"name\":\"duod\",\"full_text\":\"duodo ''${duod_val:-?} 󱑤\"}")

        # Build JSON array
        line=",["
        for i in "''${!pieces[@]}"; do
          [ "$i" -gt 0 ] && line="$line,"
          line="$line''${pieces[$i]}"
        done
        line="$line]"
        echo "$line"

        wait_tick
      done
    '';

    # Monitor config per host
    # NOTE: Run `jay randr` to discover serial numbers and connector names,
    # then replace the match fields below with your actual serial numbers
    # for stable identification across reboots.
    outputConfig =
      if hostConfig.name == "magnus"
      # toml
      then ''
        # HKC 25E3A (main, 180Hz) — update match.serial-number via `jay randr`
        [[outputs]]
        match.serial-number = "0000000000001"
        name = "main"
        x = 3840
        y = 0
        mode = { width = 1920, height = 1080, refresh-rate = 180.0 }

        # HP V222vb (secondary)
        [[outputs]]
        match.serial-number = "3CQ1261KNM"
        name = "secondary"
        x = 1920
        y = 0
        mode = { width = 1920, height = 1080, refresh-rate = 60.0 }
      ''
      else if hostConfig.name == "manus"
      # toml
      then ''
        # LG ULTRAGEAR (left monitor, scaled for readable text)
        [[outputs]]
        match.connector = "DP-2"
        name = "external"
        x = 0
        y = 0
        mode = { width = 2560, height = 1440, refresh-rate = 60.0 }

        # Lenovo laptop panel (right of external, or standalone)
        [[outputs]]
        match.connector = "eDP-1"
        name = "laptop"
        x = 2560
        y = 0
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
        unstable-mouse-follows-focus = true
        window-management-key = "Super_L"
        auto-reload = true
        show-titles = false
        workspace-display-order = "sorted"

        # ── Keyboard ─────────────────────────────────────────────────
        keymap.name = "dvorak"
        repeat-rate = { rate = 100, delay = 200 }

        # ── Startup ──────────────────────────────────────────────────
        on-startup = [
          { type = "set-env", env = { XDG_CURRENT_DESKTOP = "jay" } },
        ]

        on-graphics-initialized = [
          { type = "exec", exec = { prog = "${wlTrayBridge}/bin/wl-tray-bridge", privileged = true } },
          { type = "exec", exec = "${pkgs.networkmanagerapplet}/bin/nm-applet" },
          { type = "exec", exec = "${pkgs.pasystray}/bin/pasystray" },
          { type = "exec", exec = ["${pkgs.swaybg}/bin/swaybg", "-i", "${wallpaper}", "-m", "fill"] },
          { type = "exec", exec = "signal-desktop" },
          { type = "exec", exec = { shell = "$TERMINAL iamb" } },
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
              };
          };
        """

        [[keymaps]]
        name = "qwerty"
        rmlvo = { layout = "us", options = "caps:escape,compose:ins" }

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
        bg-color = "#000000"
        bar-bg-color = "#${config.stylix.base16Scheme.base01}"
        bar-status-text-color = "#${config.stylix.base16Scheme.base05}"
        border-color = "#${config.stylix.base16Scheme.base03}"
        focused-title-bg-color = "#${config.stylix.base16Scheme.base0D}"
        focused-title-text-color = "#${config.stylix.base16Scheme.base01}"
        unfocused-title-bg-color = "#${config.stylix.base16Scheme.base02}"
        unfocused-title-text-color = "#${config.stylix.base16Scheme.base05}"
        focused-inactive-title-bg-color = "#${config.stylix.base16Scheme.base02}"
        focused-inactive-title-text-color = "#${config.stylix.base16Scheme.base05}"
        attention-requested-bg-color = "#${config.stylix.base16Scheme.base08}"
        separator-color = "#${config.stylix.base16Scheme.base02}"
        highlight-color = "#${config.stylix.base16Scheme.base0E}"
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
        exec = "${jayStatusScript}/bin/jay-status"

        # ── Named Actions ────────────────────────────────────────────
        [actions]
        launch-terminal = { type = "exec", exec = { shell = "$TERMINAL" } }
        launch-kitty = { type = "exec", exec = "kitty" }
        launch-browser = { type = "exec", exec = "${browser}" }
        launch-browser2 = { type = "exec", exec = "${hostConfig.user.browser2}" }
        launch-vesktop = { type = "exec", exec = "vesktop" }
        launch-teams = { type = "exec", exec = ["${browser}", "--new-window", "https://teams.microsoft.com/v2/"] }
        launch-iamb = { type = "exec", exec = { shell = "$TERMINAL iamb" } }
        launch-signal = { type = "exec", exec = "signal-desktop" }

        # ── Shortcuts ────────────────────────────────────────────────
        [shortcuts]

        # ─ App launchers ─
        ${mod}-Return = "$launch-terminal"
        ${mod}-shift-Return = "$launch-kitty"
        ${mod}-b = "$launch-browser"
        ${mod}-shift-b = "$launch-browser2"
        ${mod}-d = "$launch-vesktop"
        ${mod}-shift-d = "$launch-teams"
        ${mod}-i = "$launch-iamb"
        ${mod}-shift-i = "$launch-signal"
        ${mod}-ctrl-c = "open-control-center"

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

        # ─ Clipboard history ─
        ${mod}-v = { type = "exec", exec = { shell = "${pkgs.cliphist}/bin/cliphist list | rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | wl-copy", privileged = true } }

        # ─ Calculator (rofi-calc with live preview) ─
        ${mod}-c = { type = "exec", exec = { shell = "rofi -show calc -modi calc -no-show-match -no-sort -qalc-binary qalc | wl-copy", privileged = true } }

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
        ${mod}-a = "focus-parent"
        ${mod}-space = "toggle-floating"
        ${mod}-t = "toggle-split"
        ${mod}-f = "toggle-mono"
        ${mod}-shift-f = "toggle-fullscreen"

        # ─ Screen lock ─
        ${mod}-BackSpace = { type = "exec", exec = { prog = "${pkgs.swaylock}/bin/swaylock", args = ["-c", "000000"], privileged = true } }

        # ─ Wallpaper restart ─
        ${mod}-bracketleft = { type = "exec", exec = { shell = "pkill swaybg; ${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill &" } }

        # ─ Kill electron ─
        ${mod}-ctrl-d = { type = "exec", exec = { shell = "killall electron" } }
        ${mod}-ctrl-shift-d = { type = "exec", exec = { shell = "killall .electron-wrapp; killall electron" } }

        # ─ Move workspace to other output ─
        ${mod}-o = [{ type = "move-to-output", direction = "right" }, "focus-right"]
        ${mod}-shift-o = [{ type = "move-to-output", direction = "left" }, "focus-left"]

        # ─ Focus movement (vim-style) ─
        ${mod}-h = "focus-left"
        ${mod}-j = "focus-down"
        ${mod}-k = "focus-up"
        ${mod}-l = "focus-right"

        # ─ Move windows (vim-style) ─
        ${mod}-shift-h = "move-left"
        ${mod}-shift-j = "move-down"
        ${mod}-shift-k = "move-up"
        ${mod}-shift-l = "move-right"

        # ─ Workspaces (dvorak home row: ' , . p y) ─
        ${mod}-apostrophe = { type = "show-workspace", name = "1" }
        ${mod}-comma = { type = "show-workspace", name = "2" }
        ${mod}-period = { type = "show-workspace", name = "3" }
        ${mod}-p = { type = "show-workspace", name = "4" }
        ${mod}-y = { type = "show-workspace", name = "5" }

        ${mod}-shift-apostrophe = [{ type = "move-to-workspace", name = "1" }, { type = "show-workspace", name = "1" }]
        ${mod}-shift-comma = [{ type = "move-to-workspace", name = "2" }, { type = "show-workspace", name = "2" }]
        ${mod}-shift-period = [{ type = "move-to-workspace", name = "3" }, { type = "show-workspace", name = "3" }]
        ${mod}-shift-p = [{ type = "move-to-workspace", name = "4" }, { type = "show-workspace", name = "4" }]
        ${mod}-shift-y = [{ type = "move-to-workspace", name = "5" }, { type = "show-workspace", name = "5" }]

        # ─ Split direction ─
        ${mod}-minus = "split-horizontal"
        ${mod}-shift-minus = "split-vertical"

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
        [complex-shortcuts.XF86AudioLowerVolume]
        mod-mask = ""
        action = { type = "exec", exec = ["${pkgs.pulsemixer}/bin/pulsemixer", "--change-volume", "-5"] }

        [complex-shortcuts.XF86AudioRaiseVolume]
        mod-mask = ""
        action = { type = "exec", exec = ["${pkgs.pulsemixer}/bin/pulsemixer", "--change-volume", "+5"] }

        [complex-shortcuts.XF86AudioMute]
        mod-mask = ""
        action = { type = "exec", exec = ["${pkgs.pulsemixer}/bin/pulsemixer", "--toggle-mute"] }

        [complex-shortcuts.XF86MonBrightnessUp]
        mod-mask = ""
        action = { type = "exec", exec = ["xbacklight", "-inc", "10"] }

        [complex-shortcuts.XF86MonBrightnessDown]
        mod-mask = ""
        action = { type = "exec", exec = ["xbacklight", "-dec", "10"] }

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

        [[windows]]
        match.title-regex = "^iamb"
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

        # ── Xwayland ─────────────────────────────────────────────────
        [xwayland]
        enabled = true
      '';
  in {
    home.packages = [jayPkg pkgs.satty];

    xdg.configFile."jay/config.toml".text = jayConfig;
    xdg.configFile."jay/config.so".source = "${jayConfigSo}/lib/config.so";

    # Satty config: save to downloads, copy to clipboard on save
    xdg.configFile."satty/config.toml".text = ''
      [general]
      save-after-copy = false
      copy-command = "wl-copy"
      output-filename = "$HOME/downloads/satty-%Y%m%d-%H%M%S.png"
    '';
  };
}
