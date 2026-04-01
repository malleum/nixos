{
  unify.modules.gui.home = {
    config,
    hostConfig,
    pkgs,
    ...
  }: let
    wallpaper = config.stylix.image;
    browser = hostConfig.user.browser;

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
          { type = "exec", exec = "${pkgs.mako}/bin/mako" },
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
        logo-Return = "$launch-terminal"
        logo-shift-Return = "$launch-kitty"
        logo-b = "$launch-browser"
        logo-shift-b = "$launch-browser2"
        logo-d = "$launch-vesktop"
        logo-shift-d = "$launch-teams"
        logo-i = "$launch-iamb"
        logo-shift-i = "$launch-signal"

        # ─ Clipboard copypaste ─
        logo-x = { type = "exec", exec = ["${pkgs.wl-clipboard}/bin/wl-copy", "https://xkcd.com/1475/"] }
        logo-shift-x = { type = "exec", exec = ["${pkgs.wl-clipboard}/bin/wl-copy", "Neida, jeg ville vinne"] }

        # ─ Notifications (swaync) ─
        logo-n = { type = "exec", exec = ["swaync-client", "--close-all"] }
        logo-shift-n = { type = "exec", exec = ["swaync-client", "--dnd-off"] }
        logo-ctrl-n = { type = "exec", exec = ["swaync-client", "--dnd-on"] }

        # ─ App launcher (bemenu) ─
        logo-s = { type = "exec", exec = { shell = "${pkgs.bemenu}/bin/bemenu-run --fn 'JetBrainsMono Nerd Font 13' -p 'run:' --tb '#${config.stylix.base16Scheme.base01}' --tf '#${config.stylix.base16Scheme.base0D}' --fb '#${config.stylix.base16Scheme.base01}' --ff '#${config.stylix.base16Scheme.base05}' --nb '#${config.stylix.base16Scheme.base01}' --nf '#${config.stylix.base16Scheme.base05}' --hb '#${config.stylix.base16Scheme.base0D}' --hf '#${config.stylix.base16Scheme.base01}' --sb '#${config.stylix.base16Scheme.base0D}' --sf '#${config.stylix.base16Scheme.base01}' --list 10 --center --width-factor 0.4 --border 2 --bdr '#${config.stylix.base16Scheme.base0D}'" } }

        # ─ Clipboard history ─
        logo-v = { type = "exec", exec = { shell = "${pkgs.cliphist}/bin/cliphist list | ${pkgs.bemenu}/bin/bemenu --fn 'JetBrainsMono Nerd Font 13' -p 'clip:' --list 10 --center --width-factor 0.5 --tb '#${config.stylix.base16Scheme.base01}' --hb '#${config.stylix.base16Scheme.base0D}' --hf '#${config.stylix.base16Scheme.base01}' --nb '#${config.stylix.base16Scheme.base01}' --nf '#${config.stylix.base16Scheme.base05}' | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy" } }

        # ─ Calculator (rofi-calc with live preview) ─
        logo-c = { type = "exec", exec = { shell = "rofi -show calc -modi calc -no-show-match -no-sort -qalc-binary ${pkgs.libqalculate}/bin/qalc | ${pkgs.wl-clipboard}/bin/wl-copy" } }

        # ─ Emoji picker ─
        logo-shift-e = { type = "exec", exec = ["rofi", "-modi", "emoji", "-show", "emoji"] }

        # ─ Keyboard layout switching ─
        logo-backslash = { type = "set-keymap", keymap.name = "qwerty" }
        logo-shift-backslash = { type = "set-keymap", keymap.name = "dvorak" }

        # ─ Window management ─
        logo-shift-q = "close"
        logo-ctrl-shift-semicolon = "quit"
        logo-shift-z = { type = "exec", exec = "poweroff" }
        logo-ctrl-z = { type = "exec", exec = "reboot" }

        # ─ Screenshots ─
        Print = { type = "exec", exec = { shell = "${pkgs.jay}/bin/jay screenshot --format png /tmp/jay-screenshot.png && ${pkgs.wl-clipboard}/bin/wl-copy < /tmp/jay-screenshot.png && rm /tmp/jay-screenshot.png" } }
        shift-Print = { type = "exec", exec = { shell = "${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy" } }
        logo-shift-s = { type = "exec", exec = { shell = "${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy" } }
        logo-ctrl-s = { type = "exec", exec = { shell = "${pkgs.wl-clipboard}/bin/wl-paste | ${pkgs.swappy}/bin/swappy -f - -o ~/downloads/swappy-$(date +%Y%m%d-%H%M%S).png" } }

        # ─ Floating / layout ─
        logo-a = "focus-parent"
        logo-space = "toggle-floating"
        logo-t = "toggle-split"
        logo-f = "toggle-mono"
        logo-shift-f = "toggle-fullscreen"

        # ─ Screen lock ─
        logo-BackSpace = { type = "exec", exec = { prog = "${pkgs.swaylock}/bin/swaylock", args = ["-c", "000000"], privileged = true } }

        # ─ Wallpaper restart ─
        logo-bracketleft = { type = "exec", exec = { shell = "pkill swaybg; ${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill &" } }

        # ─ Kill electron ─
        logo-ctrl-d = { type = "exec", exec = { shell = "killall electron" } }
        logo-ctrl-shift-d = { type = "exec", exec = { shell = "killall .electron-wrapp; killall electron" } }

        # ─ Move workspace to other output ─
        logo-o = { type = "move-to-output", direction = "right" }
        logo-shift-o = { type = "move-to-output", direction = "left" }

        # ─ Focus movement (vim-style) ─
        logo-h = "focus-left"
        logo-j = "focus-down"
        logo-k = "focus-up"
        logo-l = "focus-right"

        # ─ Move windows (vim-style) ─
        logo-shift-h = "move-left"
        logo-shift-j = "move-down"
        logo-shift-k = "move-up"
        logo-shift-l = "move-right"

        # ─ Workspaces (dvorak home row: ' , . p y) ─
        logo-apostrophe = { type = "show-workspace", name = "1" }
        logo-comma = { type = "show-workspace", name = "2" }
        logo-period = { type = "show-workspace", name = "3" }
        logo-p = { type = "show-workspace", name = "4" }
        logo-y = { type = "show-workspace", name = "5" }

        logo-shift-apostrophe = { type = "move-to-workspace", name = "1" }
        logo-shift-comma = { type = "move-to-workspace", name = "2" }
        logo-shift-period = { type = "move-to-workspace", name = "3" }
        logo-shift-p = { type = "move-to-workspace", name = "4" }
        logo-shift-y = { type = "move-to-workspace", name = "5" }

        # ─ Split direction ─
        logo-minus = "split-horizontal"
        logo-shift-minus = "split-vertical"

        # ─ Reload config ─
        logo-shift-r = "reload-config-toml"

        # ─ Toggle bar / titles ─
        logo-ctrl-b = "toggle-bar"

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
    home.packages = with pkgs; [
      jay
      bemenu
      grim
      libqalculate
      slurp
      swaybg
      swappy
      swaylock
      mako
    ];

    xdg.configFile."jay/config.toml".text = jayConfig;

    # Swappy config: save to downloads
    xdg.configFile."swappy/config".text = ''
      [Default]
      save_dir=$HOME/downloads
      save_filename_format=swappy-%Y%m%d-%H%M%S.png
    '';
  };
}
