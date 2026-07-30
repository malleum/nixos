# Status bar feed for jay, in the i3bar JSON protocol.
#
# Design constraints that explain the shape of this:
#   * jay spawns this and reads stdout; it is not a systemd unit, and jay
#     respawns it on config reload -- hence the killall of older instances.
#   * Audio must feel instant, so a `pactl subscribe` child wakes the loop
#     through a FIFO rather than the loop polling on a timer.
#   * Everything else is refreshed on the 2s timeout, so the slow bits never
#     gate audio latency.
{
  pkgs,
  colors,
}:
pkgs.writeShellScriptBin "jay-status" ''

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

  pactl=${pkgs.pulseaudio}/bin/pactl

  # Per-widget accent colors (base16 theme). Only the icon is colored;
  # values stay in the default bar-status-text-color for readability.
  c_audio="#${colors.base0C}"
  c_cpu="#${colors.base0D}"
  c_mem="#${colors.base0E}"
  c_disk="#${colors.base09}"
  c_bat="#${colors.base0B}"
  c_bat_low="#${colors.base08}"
  c_date="#${colors.base0A}"
  c_duod="#${colors.base0F}"
  c_dim="#${colors.base03}"
  c_bg="#${colors.base01}"   # bar bg, for invisible spacer
  c_pill="#${colors.base02}" # pill fill, one shade above the bar

  # Emit NAME as a rounded pill: accent glyph + value on a base02 fill.
  #
  # jay's i3bar reader (jay-config/src/status.rs) turns a block's `color` /
  # `background` into a pango span around the *whole* block -- and a pango
  # bgcolor is a hard rectangle, which looks like a spreadsheet cell. So the
  # fill is done in markup instead, capped by the Nerd Font powerline
  # half-circles U+E0B6 / U+E0B4 drawn in the fill color: cap, filled body,
  # cap. That is what makes the pill round. Needs JetBrainsMono Nerd Font
  # (theme.bar-font in _config.nix) -- a plain font renders tofu here.
  #
  # Two details about the spacing, both load-bearing:
  #
  #   * The space after the icon sits INSIDE the icon's own span. Nerd Font
  #     glyphs draw wider than their advance width, and pango paints each run's
  #     background rect immediately before that run's glyphs -- so with the
  #     space in the value's run, the value run's rect painted over the icon's
  #     overhang and sheared the right edge off every icon.
  #   * There are *two* spaces after the icon and one before the closing cap.
  #     The icon's overhang visually swallows the first of them, so a single
  #     space left the glyph butted against the value. The widths were tuned by
  #     rendering this markup with pango-view at bar-font size, not guessed.
  piece() {
    printf '{"name":"%s","markup":"pango","full_text":"<span foreground='"'"'%s'"'"'></span><span bgcolor='"'"'%s'"'"'><span foreground='"'"'%s'"'"'>%s  </span>%s </span><span foreground='"'"'%s'"'"'></span>"}' \
      "$1" "$c_pill" "$c_pill" "$2" "$3" "$4" "$c_pill"
  }

  # Block up to 2s. Return 0 if woken by an audio event, 1 on timeout.
  wait_tick() {
    local _d
    if read -t 2 -r _d <&9; then
      while read -t 0.01 -r _d <&9; do :; done  # drain burst (read -t 0 only polls, doesn't consume)
      return 0
    fi
    return 1
  }

  # Audio block — pactl (C, ~10ms) not pulsemixer (Python, ~150ms).
  # Re-rendered on every audio event so volume updates feel instant.
  audio_piece=""
  build_audio() {
    local mute vol icon
    mute=$($pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)
    if [ "$mute" = "Mute: yes" ]; then
      audio_piece=$(piece pulseaudio "$c_dim" "󰝟" "muted")
      return
    fi
    vol=$($pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null \
      | ${pkgs.gawk}/bin/awk '{for(i=1;i<=NF;i++) if($i ~ /%$/){gsub(/%/,"",$i); print $i; exit}}')
    icon="󰕿"
    [ "''${vol:-0}" -gt 33 ] 2>/dev/null && icon="󰖀"
    [ "''${vol:-0}" -gt 66 ] 2>/dev/null && icon="󰕾"
    audio_piece=$(piece pulseaudio "$c_audio" "$icon" "''${vol:-?}%")
  }

  # Everything else — rebuilt only on the 2s tick, never on audio events,
  # so the slow bits (df, duod) don't gate audio latency.
  slow_pieces=()

  # CPU counters carried across ticks. The old version read /proc/stat, slept
  # 0.2s, then read again -- which blocked the loop for 200ms on every tick to
  # measure a 200ms window. Diffing against the previous tick costs nothing and
  # averages over the whole 2s instead.
  # Primed here rather than left at 0, so the very first tick reports ~0%
  # rather than the machine's average CPU since boot.
  read -r _ _pu _pn _ps _pi _ < /proc/stat
  prev_busy=$(( _pu + _pn + _ps ))
  prev_total=$(( _pu + _pn + _ps + _pi ))

  build_slow() {
    slow_pieces=()
    local key val

    # CPU — read /proc/stat directly (no subprocesses)
    local u n s i busy total dbusy dtotal cpu
    read -r _ u n s i _ < /proc/stat
    busy=$(( u + n + s ))
    total=$(( u + n + s + i ))
    dbusy=$(( busy - prev_busy ))
    dtotal=$(( total - prev_total ))
    prev_busy=$busy
    prev_total=$total
    if [ "$dtotal" -gt 0 ]; then
      cpu=$(( dbusy * 100 / dtotal ))
    else
      cpu=0
    fi
    slow_pieces+=("$(piece cpu "$c_cpu" "󰍛" "$(printf '%02d' $cpu)%")")

    # Memory — read /proc/meminfo directly (no subprocesses)
    local mem_total mem_avail mem_used_kb mem_used_mb mem_gb mem_frac
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
      slow_pieces+=("$(piece memory "$c_mem" "󰾅" "$mem_gb.''${mem_frac}G")")
    else
      slow_pieces+=("$(piece memory "$c_mem" "󰾅" "?G")")
    fi

    # Disk — one df call
    local disk_pct
    disk_pct=$(df --output=pcent / 2>/dev/null | tail -1 | tr -dc '0-9')
    slow_pieces+=("$(piece disk "$c_disk" "󰋊" "$(printf '%02d' "''${disk_pct:-0}")%")")

    # Battery (only if battery exists) — read /sys directly
    if [ -d /sys/class/power_supply/BAT0 ]; then
      local bat_cap bat_status bat_icon bat_col
      bat_cap=$(< /sys/class/power_supply/BAT0/capacity)
      bat_status=$(< /sys/class/power_supply/BAT0/status)
      bat_col=$c_bat
      if [ "$bat_status" = "Charging" ] || [ "$bat_status" = "Full" ]; then
        bat_icon="󰂄"
      else
        bat_icon="󰁹"
        [ "''${bat_cap:-100}" -le 15 ] && bat_col=$c_bat_low
      fi
      slow_pieces+=("$(piece battery "$bat_col" "$bat_icon" "''${bat_cap:-?}%")")
    fi

    # Date
    local date_str
    date_str=$(date '+%m-%d')
    slow_pieces+=("$(piece clock "$c_date" "󰸗" "$date_str")")

    # Duodo clock — timeout to prevent hangs.
    # duod prints 5 base-12 digits; the last one changes ~7x/second, so it is
    # dropped. Was `| choose -c 0..4` -- a whole subprocess per tick to do what
    # a substring does.
    local duod_val
    duod_val=$(timeout 1 duod 2>/dev/null)
    duod_val="''${duod_val:0:4}"
    slow_pieces+=("$(piece duod "$c_duod" "󰔛" "''${duod_val:-?}")")

    # Gap before the tray: jay sizes the status by ink-rect, which drops
    # trailing spaces but not glyph ink, so a block of invisible glyph ink
    # reserves width without showing.
    #
    # Two changes from the old bar-bg-colored version: it is its own block
    # rather than part of the duod pill (inside the pill a base01 glyph shows
    # against the base02 fill), and it hides via pango `alpha` instead of
    # painting itself the bar color -- the bar is translucent now, so an
    # opaque base01 block would no longer match it. jay feeds the markup to
    # pango_layout_set_markup, so the alpha attribute is honored.
    slow_pieces+=("{\"name\":\"spacer\",\"markup\":\"pango\",\"full_text\":\"<span foreground='$c_bg' alpha='1%'>█</span>\"}")
  }

  print_line() {
    local line=",[$audio_piece" p
    for p in "''${slow_pieces[@]}"; do
      line="$line,$p"
    done
    echo "$line]"
  }

  build_slow
  while true; do
    build_audio
    print_line
    wait_tick || build_slow   # audio event: re-render audio only; timeout: refresh the rest
  done
''
