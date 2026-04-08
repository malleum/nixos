{
  unify.modules.gui.home = {
    config,
    hostConfig,
    pkgs,
    ...
  }: let
    wallpaper = config.stylix.image;
    browser = hostConfig.user.browser;
    mod = "logo";

    # Jay status bar script using i3bar JSON protocol
    # bash
    jayStatusScript = pkgs.writeShellScript "jay-status" ''
      echo '{"version":1}'
      echo '['
      echo '[]'
      while true; do
        pieces=()

        # System tray is built into jay's bar, no need for tray module

        # Audio (pulseaudio)
        vol=$(${pkgs.pulsemixer}/bin/pulsemixer --get-volume 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $1}')
        mute=$(${pkgs.pulsemixer}/bin/pulsemixer --get-mute 2>/dev/null)
        if [ "$mute" = "1" ]; then
          pieces+=("{\"name\":\"pulseaudio\",\"full_text\":\"audio: muted 󰝟\"}")
        else
          icon=""
          [ "$vol" -gt 50 ] 2>/dev/null && icon=""
          [ "$vol" -gt 75 ] 2>/dev/null && icon=""
          pieces+=("{\"name\":\"pulseaudio\",\"full_text\":\"audio ''${vol:-?}% $icon\"}")
        fi

        # Network
        net_info=$(${pkgs.networkmanager}/bin/nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null | ${pkgs.gnugrep}/bin/grep -m1 ':connected:')
        if [ -n "$net_info" ]; then
          net_type=$(echo "$net_info" | cut -d: -f1)
          net_name=$(echo "$net_info" | cut -d: -f3)
          if [ "$net_type" = "wifi" ]; then
            signal=$(${pkgs.networkmanager}/bin/nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | ${pkgs.gnugrep}/bin/grep '^\*' | cut -d: -f2)
            pieces+=("{\"name\":\"network\",\"full_text\":\"net ''${signal:-?}% \"}")
          else
            pieces+=("{\"name\":\"network\",\"full_text\":\"net: 󰈀\"}")
          fi
        else
          pieces+=("{\"name\":\"network\",\"full_text\":\"net: disconnected ⚠\",\"urgent\":true}")
        fi

        # CPU
        cpu=$(${pkgs.procps}/bin/ps -A -o pcpu 2>/dev/null | ${pkgs.gawk}/bin/awk '{s+=$1} END {printf "%02d", s/NR*NR/100}' 2>/dev/null || echo "?")
        # Simpler: read from /proc/stat
        read -r _ u1 n1 s1 i1 _ < /proc/stat
        sleep 0.05
        read -r _ u2 n2 s2 i2 _ < /proc/stat
        total=$(( (u2+n2+s2+i2) - (u1+n1+s1+i1) ))
        idle=$(( i2 - i1 ))
        if [ "$total" -gt 0 ]; then
          cpu=$(( (total - idle) * 100 / total ))
        else
          cpu=0
        fi
        pieces+=("{\"name\":\"cpu\",\"full_text\":\"cpu $(printf '%02d' $cpu)% 󰍛\"}")

        # Memory
        mem_used=$(${pkgs.procps}/bin/free -m 2>/dev/null | ${pkgs.gawk}/bin/awk '/^Mem:/ {printf "%.1f", $3/1024}')
        pieces+=("{\"name\":\"memory\",\"full_text\":\"mem ''${mem_used:-?}G 󰾅\"}")

        # Disk
        disk_pct=$(df -h / 2>/dev/null | ${pkgs.gawk}/bin/awk 'NR==2 {gsub(/%/,""); print $5}')
        pieces+=("{\"name\":\"disk\",\"full_text\":\"disk $(printf '%02d' "''${disk_pct:-0}")% 󰋊\"}")

        # Battery (only if battery exists)
        if [ -d /sys/class/power_supply/BAT0 ]; then
          bat_cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
          bat_status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
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

        # Duodo clock
        duod_val=$(duod 2>/dev/null | ${pkgs.choose}/bin/choose -c 0..4)
        pieces+=("{\"name\":\"duod\",\"full_text\":\"duodo ''${duod_val:-?} 󱑤\"}")

        # Build JSON array
        line=",["
        for i in "''${!pieces[@]}"; do
          [ "$i" -gt 0 ] && line="$line,"
          line="$line''${pieces[$i]}"
        done
        line="$line]"
        echo "$line"

        sleep 1
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
        x = 1920
        y = 0
        mode = { width = 1920, height = 1080, refresh-rate = 180.0 }

        # HP V222vb (secondary)
        [[outputs]]
        match.serial-number = "3CQ1261KNM"
        name = "secondary"
        x = 0
        y = 0
        mode = { width = 1920, height = 1080, refresh-rate = 60.0 }
      ''
      else if hostConfig.name == "manus"
      # toml
      then ''
        # Lenovo laptop panel
        [[outputs]]
        match.connector = "eDP-1"
        name = "laptop"
        x = 2560
        y = 0
        mode = { width = 1920, height = 1200, refresh-rate = 60.0 }

        # LG ULTRAGEAR (left monitor)
        [[outputs]]
        match.serial-number = "0x0004A026"
        name = "external"
        x = 0
        y = 0
        mode = { width = 2560, height = 1440, refresh-rate = 60.0 }
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

        # ── Keyboard ─────────────────────────────────────────────────
        keymap.name = "dvorak"

        [[keymaps]]
        name = "dvorak"
        rmlvo = { layout = "us", variants = "dvorak", options = "caps:escape,compose:ins" }

        [[keymaps]]
        name = "qwerty"
        rmlvo = { layout = "us", options = "caps:escape,compose:ins" }

        repeat-rate = { rate = 50, delay = 225 }

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
        # Pointer settings (accel-profile applies to mice, touchpad settings
        # are silently ignored on non-touchpad devices)
        [[inputs]]
        match.is-pointer = true
        accel-profile = "Flat"
        accel-speed = 0.0
        natural-scrolling = true
        tap-enabled = true
        tap-drag-enabled = true

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
        focused-inactive-title-bg-color = "#${config.stylix.base16Scheme.base03}"
        focused-inactive-title-text-color = "#${config.stylix.base16Scheme.base05}"
        attention-requested-bg-color = "#${config.stylix.base16Scheme.base08}"
        separator-color = "#${config.stylix.base16Scheme.base02}"
        highlight-color = "#${config.stylix.base16Scheme.base0E}"
        border-width = 2
        title-height = 24
        bar-height = 32
        font = "JetBrainsMono Nerd Font 10"
        title-font = "JetBrainsMono Nerd Font 10"
        bar-font = "JetBrainsMono Nerd Font 13"
        bar-position = "top"

        # ── Status Bar ───────────────────────────────────────────────
        [status]
        format = "i3bar"
        exec = "${jayStatusScript}"

        # ── Idle ─────────────────────────────────────────────────────
        idle = { minutes = 10 }

        on-idle = {
          type = "exec",
          exec = { prog = "${pkgs.swaylock}/bin/swaylock", args = ["-c", "000000"], privileged = true },
        }

        # ── Startup ──────────────────────────────────────────────────
        on-startup = [
          { type = "set-env", env = { XDG_CURRENT_DESKTOP = "jay" } },
        ]

        on-graphics-initialized = [
          { type = "exec", exec = "${pkgs.networkmanagerapplet}/bin/nm-applet" },
          { type = "exec", exec = ["${pkgs.swaybg}/bin/swaybg", "-i", "${wallpaper}", "-m", "fill"] },
          { type = "exec", exec = "signal-desktop" },
          { type = "exec", exec = { shell = "$TERMINAL iamb" } },
        ]

        # ── Named Actions ────────────────────────────────────────────
        [actions]
        launch-terminal = { type = "exec", exec = { shell = "$TERMINAL" } }
        launch-kitty = { type = "exec", exec = "kitty" }
        launch-browser = { type = "exec", exec = "${browser}" }
        launch-browser2 = { type = "exec", exec = "${hostConfig.user.browser2}" }
        launch-vesktop = { type = "exec", exec = "vesktop" }
        launch-teams = { type = "exec", exec = ["${browser}", "https://teams.microsoft.com/v2/"] }
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

        # ─ Clipboard copypaste ─
        ${mod}-x = { type = "exec", exec = ["${pkgs.wl-clipboard}/bin/wl-copy", "https://xkcd.com/1475/"] }
        ${mod}-shift-x = { type = "exec", exec = ["${pkgs.wl-clipboard}/bin/wl-copy", "Neida, jeg ville vinne"] }

        # ─ Notifications (swaync) ─
        ${mod}-n = { type = "exec", exec = ["swaync-client", "--close-all"] }
        ${mod}-shift-n = { type = "exec", exec = { shell = "swaync-client --dnd-off && notify-send 'Notifications Enabled' -t 1000" } }
        ${mod}-ctrl-n = { type = "exec", exec = { shell = "notify-send 'Notifications Disabled' -t 300; sleep 0.3; swaync-client --dnd-on" } }
        ${mod}-ctrl-shift-n = { type = "exec", exec = ["swaync-client", "-a", "0"] }

        # ─ App launcher (rofi) ─
        ${mod}-s = { type = "exec", exec = { shell = "rofi -show drun" } }

        # ─ Clipboard history ─
        ${mod}-v = { type = "exec", exec = { shell = "${pkgs.cliphist}/bin/cliphist list | rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | wl-copy" } }

        # ─ Calculator (rofi-calc with live preview) ─
        ${mod}-c = { type = "exec", exec = { shell = "rofi -show calc -modi calc -no-show-match -no-sort -qalc-binary qalc | wl-copy" } }

        # ─ Emoji picker ─
        ${mod}-shift-e = { type = "exec", exec = ["rofi", "-modi", "emoji", "-show", "emoji"] }

        # ─ Keyboard layout switching ─
        ${mod}-backslash = { type = "set-keymap", keymap.name = "qwerty" }
        ${mod}-shift-backslash = { type = "set-keymap", keymap.name = "dvorak" }

        # ─ Window management ─
        ${mod}-shift-q = "close"
        ${mod}-ctrl-shift-semicolon = "quit"
        ${mod}-shift-z = { type = "exec", exec = "poweroff" }
        ${mod}-ctrl-z = { type = "exec", exec = "reboot" }

        # ─ Screenshots ─
        Print = { type = "exec", exec = { shell = "${pkgs.hyprshot}/bin/hyprshot -m active -z --clipboard-only" } }
        shift-Print = { type = "exec", exec = { shell = "${pkgs.hyprshot}/bin/hyprshot -m region -z --clipboard-only" } }
        ${mod}-shift-s = { type = "exec", exec = { shell = "${pkgs.hyprshot}/bin/hyprshot -m region --clipboard-only" } }
        ${mod}-ctrl-s = { type = "exec", exec = { shell = "wl-paste | ${pkgs.swappy}/bin/swappy -f -" } }

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
        ${mod}-o = { type = "move-to-output", direction = "right" }
        ${mod}-shift-o = { type = "move-to-output", direction = "left" }

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

        ${mod}-shift-apostrophe = { type = "move-to-workspace", name = "1" }
        ${mod}-shift-comma = { type = "move-to-workspace", name = "2" }
        ${mod}-shift-period = { type = "move-to-workspace", name = "3" }
        ${mod}-shift-p = { type = "move-to-workspace", name = "4" }
        ${mod}-shift-y = { type = "move-to-workspace", name = "5" }

        # ─ Split direction ─
        ${mod}-minus = "split-horizontal"
        ${mod}-shift-minus = "split-vertical"

        # ─ Reload config ─
        ${mod}-shift-r = "reload-config-toml"

        # ─ Toggle bar / titles ─
        ${mod}-ctrl-b = "toggle-bar"

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
        match.just-mapped = true
        action = { type = "move-to-workspace", name = "2" }

        [[windows]]
        match.title-regex = ".*Brave.*"
        match.just-mapped = true
        action = { type = "move-to-workspace", name = "1" }

        [[windows]]
        match.title-regex = ".*Firefox.*"
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
        match.title-regex = "^iamb.*"
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
        match.title-regex = ".*Steam.*"
        match.just-mapped = true
        action = { type = "move-to-workspace", name = "4" }

        [[windows]]
        match.title-regex = ".*Minecraft.*"
        match.just-mapped = true
        action = { type = "move-to-workspace", name = "4" }

        [[windows]]
        match.title-regex = ".*Prism Launcher.*"
        match.just-mapped = true
        action = { type = "move-to-workspace", name = "4" }

        [[windows]]
        match.title-regex = ".*Terraria.*"
        match.just-mapped = true
        action = { type = "move-to-workspace", name = "4" }

        [[windows]]
        match.title-regex = ".*War.*"
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

        # ── Xwayland ─────────────────────────────────────────────────
        [xwayland]
        enabled = true
      '';
  in {
    home.packages = [ pkgs.jay ];

    xdg.configFile."jay/config.toml".text = jayConfig;

    # Swappy config: save to downloads
    xdg.configFile."swappy/config".text = ''
      [Default]
      save_dir=$HOME/downloads
      save_filename_format=swappy-%Y%m%d-%H%M%S.png
    '';
  };
}
