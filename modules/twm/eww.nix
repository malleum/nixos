{
  config,
  lib,
  pkgs,
  ...
}: let
  indexOf = list: item: let
    indexHelper = l: i:
      if l == []
      then -1
      else if builtins.elemAt l 0 == item
      then i
      else indexHelper (builtins.tail l) (i + 1);
  in
    indexHelper list 0;

  colors = [
    "#${config.stylix.base16Scheme.base09}"
    "#${config.stylix.base16Scheme.base0A}"
    "#${config.stylix.base16Scheme.base0B}"
    "#${config.stylix.base16Scheme.base0C}"
  ];

  mods =
    if (config.networking.hostName == "magnus")
    then ["battery" "tray" "pulseaudio" "network" "cpu" "temperature" "disk" "clock2" "clock" "duod"]
    else ["tray" "pulseaudio" "network" "cpu" "temperature" "disk" "battery" "clock2" "clock" "duod"];

  modulo' = a: b: a - b * builtins.div a b;
  modulo = a: (modulo' a (builtins.length colors));
  c = lib.attrsets.genAttrs mods (mod: (builtins.elemAt colors (modulo (indexOf mods mod))));

  # Eww scripts
  startup-eww-bar =
    pkgs.writeShellScriptBin "startup-eww-bar"
    # bash
    ''
      #!/usr/bin/env bash

      # Kill any existing Eww instances
      eww kill

      # Start Eww daemon
      eww daemon

      # Wait a bit for the daemon to fully start
      sleep 1

      # Open the Eww bar window
      eww open bar
    '';

  battery-script =
    pkgs.writeShellScriptBin "battery-eww"
    # bash
    ''
      #!/usr/bin/env bash
      battery_path="/sys/class/power_supply/BAT0"
      if [ -d "$battery_path" ]; then
        capacity=$(cat "$battery_path/capacity" 2>/dev/null || echo "0")
        status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")

        case $status in
          "Charging") icon="" ;;
          "Full") icon="" ;;
          *)
            if [ "$capacity" -ge 90 ]; then icon=""
            elif [ "$capacity" -ge 70 ]; then icon=""
            elif [ "$capacity" -ge 50 ]; then icon=""
            elif [ "$capacity" -ge 30 ]; then icon=""
            else icon=""
            fi
            ;;
        esac

        echo "{\"capacity\": $capacity, \"status\": \"$status\", \"icon\": \"$icon\"}"
      else
        echo "{\"capacity\": 0, \"status\": \"Not available\", \"icon\": \"\"}"
      fi
    '';

  hypr-workspaces-eww-script =
    pkgs.writeShellScriptBin "hypr-workspaces-eww"
    # bash
    ''
      #!/usr/bin/env bash

      # Define your workspace symbols (using Nerd Font compatible symbols)
      # You can customize these if you have a specific font like your 𝋁, 𝋂, etc.
      # But for general compatibility, Font Awesome symbols are recommended.
      SYMBOL_EMPTY=""    # Circle outline
      SYMBOL_OCCUPIED="" # Circle filled
      SYMBOL_ACTIVE=""   # Circle with dot (active)
      SYMBOL_SPECIAL="󰏖" # A distinct symbol for special workspaces (e.g., sticky)
      SYMBOL_URGENT=""   # Exclamation mark for urgent windows

      # Function to get Hyprland workspace info and format for Eww
      get_workspaces_json() {
          local -a workspaces_array=()
          local -i current_workspace_id=$(hyprctl activeworkspace -j | jq -r '.id')

          # Get all workspaces (including empty ones)
          hyprctl workspaces -j | jq -c '.[]' | while read -r workspace_json; do
              local id=$(echo "$workspace_json" | jq -r '.id')
              local name=$(echo "$workspace_json" | jq -r '.name')
              local windows=$(echo "$workspace_json" | jq -r '.windows')
              local focused=$(echo "$workspace_json" | jq -r '.focused')
              local has_urgent=false # Placeholder for urgent status (more complex to get directly from hyprctl workspaces)

              # Determine symbol based on state
              local symbol="$SYMBOL_EMPTY"
              if [ "$windows" -gt 0 ]; then
                  symbol="$SYMBOL_OCCUPIED"
              fi
              if [ "$focused" = "true" ]; then
                  symbol="$SYMBOL_ACTIVE"
              fi
              # Add logic for urgent if you can detect it (e.g., from activewindow events)
              # if $has_urgent; then
              #    symbol="$SYMBOL_URGENT"
              # fi

              workspaces_array+=( "{ \"id\": $id, \"name\": \"$name\", \"focused\": $focused, \"windows\": $windows, \"symbol\": \"$symbol\" }" )
          done

          # Join the array elements with commas and wrap in a JSON array
          printf "[%s]\n" "$(IFS=,; echo "''${workspaces_array[*]}")"
      }

      # Initial output when Eww starts
      get_workspaces_json

      # Listen for Hyprland events and trigger updates
      hyprctl event | while IFS= read -r event; do
          case "$event" in
              # Workspace events
              "workspace>>"* | \
              "focusedworkspace>>"* | \
              "createworkspace>>"* | \
              "destroyworkspace>>"* | \
              "moveworkspace>>"* | \
              "activewindow>>"* | \
              "windowopened>>"* | \
              "windowclosed>>"* )
                  get_workspaces_json
                  ;;
          esac
      done
    '';

  temperature-script =
    pkgs.writeShellScriptBin "temperature-eww"
    # bash
    ''
      #!/usr/bin/env bash

      # Try different methods to get CPU temperature
      temp=""

      # Method 1: Try sensors with different core patterns
      if command -v sensors >/dev/null 2>&1; then
        temp=$(sensors 2>/dev/null | grep -E "(Core 0|Package id 0|Tctl)" | head -1 | grep -o '+[0-9]*' | head -1 | tr -d '+')
      fi

      # Method 2: Try thermal zone if sensors failed
      if [ -z "$temp" ] && [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temp_millidegrees=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        if [ -n "$temp_millidegrees" ] && [ "$temp_millidegrees" -gt 0 ]; then
          temp=$((temp_millidegrees / 1000))
        fi
      fi

      # Method 3: Try other thermal zones
      if [ -z "$temp" ]; then
        for zone in /sys/class/thermal/thermal_zone*/temp; do
          if [ -f "$zone" ]; then
            temp_millidegrees=$(cat "$zone" 2>/dev/null)
            if [ -n "$temp_millidegrees" ] && [ "$temp_millidegrees" -gt 0 ] && [ "$temp_millidegrees" -lt 150000 ]; then
              temp=$((temp_millidegrees / 1000))
              break
            fi
          fi
        done
      fi

      # Default to 0 if no temperature found
      temp=''${temp:-0}

      # Ensure it's a valid number
      if ! [[ "$temp" =~ ^[0-9]+$ ]]; then
        temp=0
      fi

      echo "$temp"
    '';

  network-script =
    pkgs.writeShellScriptBin "network-eww"
    ''
      #!/usr/bin/env bash

      connected="false"
      signal=0
      icon="⚠"

      # Check WiFi
      if nmcli -t -f WIFI g 2>/dev/null | grep -q "enabled"; then
        signal=$(nmcli -t -f SIGNAL dev wifi 2>/dev/null | head -1)
        if [ -n "$signal" ] && [ "$signal" != "--" ] && [ "$signal" -gt 0 ]; then
          connected="true"
          icon=""
        fi
      fi

      # Check ethernet if WiFi failed
      if [ "$connected" = "false" ] && nmcli -t -f STATE g 2>/dev/null | grep -q "connected"; then
        connected="true"
        signal=100
        icon=""
      fi

      echo "{\"connected\": $connected, \"signal\": $signal, \"icon\": \"$icon\"}"
    '';

  audio-script =
    pkgs.writeShellScriptBin "audio-eww"
    # bash
    ''
      #!/usr/bin/env bash

      # Get volume and mute status
      volume=$("${pkgs.pulseaudioFull}/bin/pactl" get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%')
      muted=$("${pkgs.pulseaudioFull}/bin/pactl" get-sink-mute @DEFAULT_SINK@ | grep -o 'yes\|no')

      # Get source (microphone) volume
      source_volume=$("${pkgs.pulseaudioFull}/bin/pactl" get-source-volume @DEFAULT_SOURCE@ | grep -o '[0-9]*%' | head -1 | tr -d '%')
      source_muted=$("${pkgs.pulseaudioFull}/bin/pactl" get-source-mute @DEFAULT_SOURCE@ | grep -o 'yes\|no')

      # Provide defaults if values are empty
      volume=''${volume:-0}
      source_volume=''${source_volume:-0}
      muted=''${muted:-no}
      source_muted=''${source_muted:-no}

      if [ "$muted" = "yes" ]; then
        icon=""
      else
        if [ "$volume" -ge 70 ]; then icon=""
        elif [ "$volume" -ge 30 ]; then icon=""
        else icon=""
        fi
      fi

      source_icon=""
      if [ "$source_muted" = "yes" ]; then
        source_icon=""
      fi

      echo "{\"volume\": $volume, \"muted\": \"$muted\", \"icon\": \"$icon\", \"source_volume\": $source_volume, \"source_muted\": \"$source_muted\", \"source_icon\": \"$source_icon\"}"
    '';

  duod-eww-script = pkgs.writeShellScriptBin "duod-eww" ''
    #!/usr/bin/env bash

    # Convert hex digits to decimal (a=10, b=11)
    hex_to_dec() {
        case $1 in
            a) echo 10 ;;
            b) echo 11 ;;
            *) echo $1 ;;
        esac
    }

    # Get duod output and parse values
    duod_output=$(duod | choose 2:)
    read -r outer middle inner <<< "$duod_output"

    # Convert to decimal
    outer_val=$(hex_to_dec "$outer")
    middle_val=$(hex_to_dec "$middle")
    inner_val=$(hex_to_dec "$inner")

    # Calculate stroke-dasharray
    calc_dash() {
        local value=$1
        local circ=$2
        local filled=$(( value * circ / 12 ))
        local empty=$(( circ - filled ))
        echo "$filled $empty"
    }

    outer_dash=$(calc_dash $outer_val 63)
    middle_dash=$(calc_dash $middle_val 38)
    inner_dash=$(calc_dash $inner_val 19)

    # Generate unique filename with timestamp to prevent caching
    timestamp=$(date +%s%N)
    svg_file="/tmp/duod_$timestamp.svg"

    # Remove old duod SVG files (keep only last 5)
    ls -t /tmp/duod_*.svg 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true

    # Create new SVG file
    cat > "$svg_file" << EOF
    <svg width='28' height='28' viewBox='0 0 28 28' xmlns='http://www.w3.org/2000/svg'>
      <circle cx='14' cy='14' r='11' fill='none' stroke='#45b7d1' stroke-width='2.5' stroke-dasharray='$outer_dash' stroke-linecap='round' transform='rotate(-90 14 14)'/>
      <circle cx='14' cy='14' r='7' fill='none' stroke='#3eed84' stroke-width='2.5' stroke-dasharray='$middle_dash' stroke-linecap='round' transform='rotate(-90 14 14)'/>
      <circle cx='14' cy='14' r='3.5' fill='none' stroke='#eeee22' stroke-width='2.5' stroke-dasharray='$inner_dash' stroke-linecap='round' transform='rotate(-90 14 14)'/>
    </svg>
    EOF

    echo "$svg_file"
  '';

  eww-config = pkgs.writeTextFile {
    name = "eww.yuck";
    text =
      # yuck
      ''
        ;; Variables and Polls
        (defpoll time_full :interval "1s" "date '+%H:%M:%S'")
        (defpoll time_date :interval "60s" "date '+%m-%d'")
        (defpoll duod_svg :interval "1s" "duod-eww")
        (defpoll battery_info :interval "5s" :initial "{}" "battery-eww")
        (defpoll network_info :interval "5s" :initial "{}" "network-eww")
        (defpoll audio_info :interval "1s" :initial "{}" "audio-eww")
        (defpoll cpu_usage :interval "2s" :initial "0" "grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage)}'")
        (defpoll temp_info :interval "3s" :initial "0" "temperature-eww")
        (defpoll disk_usage :interval "60s" :initial "0" "df / | awk 'NR==2 {print int($5)}' | tr -d '%'")
        (defpoll memory_usage :interval "2s" :initial "0" "free | awk 'NR==2{printf \"%.0f\", $3*100/$2}'")

        ;; Workspaces
        (deflisten workspaces :initial "[]" "hypr-workspaces-eww")

        ;; Widgets
        (defwidget workspaces_widget []
          (box :class "workspaces" :space-evenly false :halign "start"
            (for workspace in workspaces
              (button :class "workspace-button ''${workspace.focused ? 'active' : ""} ''${workspace.urgent ? 'urgent' : ""}"
                      :onclick "hyprctl dispatch workspace ''${workspace.name}"
                (label :text "''${workspace.name == '1' ? '𝋁' :
                               workspace.name == '2' ? '𝋂' :
                               workspace.name == '3' ? '𝋃' :
                               workspace.name == '4' ? '𝋄' :
                               workspace.name == '5' ? '𝋅' : workspace.symbol}")))))

        (defwidget battery_widget []
          (box :class "battery" :space-evenly false
            (label :text "''${battery_info.capacity} ''${battery_info.icon}")))

        (defwidget clock_widget []
          (box :class "clock" :space-evenly false
            (label :text time_full)))

        (defwidget clock2_widget []
          (box :class "clock2" :space-evenly false
            (label :text time_date)))

        (defwidget duod_widget []
          (box :class "duod" :space-evenly false
            (image :path duod_svg :image-width 28 :image-height 28)))

        (defwidget network_widget []
          (box :class "network" :space-evenly false
            (button :onclick "nm-connection-editor"
              (label :text "''${network_info.connected == "true" ? network_info.signal : 0} ''${network_info.icon}"))))

        (defwidget audio_widget []
          (box :class "pulseaudio" :space-evenly false
            (button :onclick "pavucontrol"
              (label :text "''${audio_info.volume} ''${audio_info.icon} ''${audio_info.source_volume} ''${audio_info.source_icon}"))))

        (defwidget cpu_widget []
          (box :class "cpu" :space-evenly false
            (label :text "''${cpu_usage} 󰍛")))

        (defwidget temperature_widget []
          (box :class "temperature" :space-evenly false
            (label :text "''${temp_info} ''${temp_info > 80 ? "" : temp_info > 60 ? "" : ""}")))

        (defwidget disk_widget []
          (box :class "disk" :space-evenly false
            (label :text "''${disk_usage} ⬤")))

        (defwidget memory_widget []
          (box :class "memory" :space-evenly false
            (label :text "''${memory_usage}% ")))

        (defwidget tray_widget []
          (box :class "tray" :space-evenly false
            (systray :space-evenly false :spacing 10 :icon-size 16)))

        ;; Main bar
        (defwidget bar_modules [modules]
          (box :class "modules" :space-evenly false :spacing 6
            (for module in modules
              (literal :content {module == "battery" ? "(battery_widget)" :
                                module == "clock" ? "(clock_widget)" :
                                module == "clock2" ? "(clock2_widget)" :
                                module == "duod" ? "(duod_widget)" :
                                module == "network" ? "(network_widget)" :
                                module == "pulseaudio" ? "(audio_widget)" :
                                module == "cpu" ? "(cpu_widget)" :
                                module == "temperature" ? "(temperature_widget)" :
                                module == "disk" ? "(disk_widget)" :
                                module == "memory" ? "(memory_widget)" :
                                module == "tray" ? "(tray_widget)" : ""}))))

        (defwidget bar []
          (centerbox :orientation "h" :class "bar"
            (box :class "left" :halign "start" :space-evenly false
              (workspaces_widget))
            ${
          if (config.networking.hostName == "magnus")
          then ''
            (box :class "center" :halign "center" :space-evenly false
              (bar_modules :modules '["tray", "pulseaudio", "network", "cpu", "temperature", "disk", "clock2", "clock", "duod"]')
            (box :class "right" :halign "end")
          ''
          else ''
            (box :class "center" :halign "center")
            (box :class "right" :halign "end" :space-evenly false
              (bar_modules :modules '["tray", "pulseaudio", "network", "cpu", "temperature", "disk", "battery", "clock2", "clock", "duod"]'))
          ''
        }))

        ;; Windows
        (defwindow bar
          :monitor 0
          :windowtype "dock"
          :geometry (geometry :x "0%"
                             :y "0%"
                             :width "100%"
                             :height "30px"
                             :anchor "top center")
          :reserve (struts :side "top" :distance "30px")
          (bar))

      '';
  };

  eww-css = pkgs.writeTextFile {
    name = "eww.scss";
    text =
      # css
      ''
        * {
          all: unset;
          font-family: "JetBrainsMono";
          font-size: 16px;
        }

        .bar {
          background: transparent;
          color: #ffffff;
          padding: 0 10px;
        }

        .left, .center, .right {
          padding: 0 5px;
        }

        .modules {
          padding: 0;
        }

        .workspaces {
          margin: 0 4px;
          color: ${c.temperature or "#ffffff"};
        }

        .workspace-button {
          padding: 0 10px;
          margin: 0 5px;
          border-radius: 6px;
          color: #ffffff;
          background-color: ${c.duod or "#333333"};
          min-width: 30px;

          &.active {
            color: #000000;
            background-color: ${c.clock or "#ffffff"};
          }

          &.urgent {
            color: ${c.temperature or "#ff0000"};
          }
        }

        .battery, .clock, .clock2, .duod, .network, .pulseaudio,
        .cpu, .temperature, .disk, .memory, .tray {
          padding: 4 10px;
          border-radius: 6px;
          color: #000000;
        }

        .clock {
          background-color: ${c.clock or "#ffffff"};
        }

        .clock2 {
          background-color: ${c.clock2 or "#cccccc"};
        }

        .duod {
          background-color: #000000;
          padding: 1px 8px;
          min-width: 32px;
          min-height: 30px;
        }

        .battery {
          background-color: ${c.battery or "#00ff00"};

          &.charging, &.plugged {
            color: #ffffff;
          }

          &.critical {
            background-color: #f53c3c;
            color: #ffffff;
            animation: blink 0.5s linear infinite alternate;
          }
        }

        .network {
          background-color: ${c.network or "#0088cc"};

          &.disconnected {
            background-color: #f53c3c;
            color: #ffffff;
          }
        }

        .pulseaudio {
          background-color: ${c.pulseaudio or "#ff8800"};

          &.muted {
            background-color: #${config.stylix.base16Scheme.base01 or "444444"};
            color: #${config.stylix.base16Scheme.base07 or "ffffff"};
          }
        }

        .cpu {
          background-color: ${c.cpu or "#8800ff"};
        }

        .temperature {
          background-color: ${c.temperature or "#ff0088"};

          &.critical {
            background-color: #eb4d4b;
          }
        }

        .disk {
          background-color: ${c.disk or "#00ff88"};
        }

        .memory {
          background-color: ${c.memory or "#88ff00"};
        }

        .tray {
          background-color: ${c.tray or "#888888"};
        }

        @keyframes blink {
          to {
            background-color: #ffffff;
            color: #000000;
          }
        }
      '';
  };
in {
  environment.systemPackages = [
    pkgs.eww
    duod-eww-script
    battery-script
    network-script
    audio-script
    temperature-script
    hypr-workspaces-eww-script
    startup-eww-bar
  ];

  home-manager.users.joshammer = {
    xdg.configFile."eww/eww.yuck".source = eww-config;
    xdg.configFile."eww/eww.scss".source = eww-css;

  };
}
