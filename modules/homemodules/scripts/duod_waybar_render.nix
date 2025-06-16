{pkgs, ...}:
pkgs.writeShellScriptBin "duod-waybar-render" ''
    #!/usr/bin/env bash

    # Convert hex digits to decimal (a=10, b=11)
    hex_to_dec() {
        case $1 in
            a) echo 10 ;;
            b) echo 11 ;;
            *) echo $1 ;;
        esac
    }

    # Get duod output and parse x y z values
    duod_output=$(duod | choose :2)
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
    middle_dash=$(calc_dash $middle_val 44)
    inner_dash=$(calc_dash $inner_val 25)

    # Create SVG file in /tmp
    svg_file="/tmp/duod_waybar.svg"
    cat > "$svg_file" << EOF
  <svg width='36' height='36' viewBox='0 0 36 36' xmlns='http://www.w3.org/2000/svg'>
    <circle cx='12' cy='12' r='10' fill='none' stroke='#ff6b6b' stroke-width='3' stroke-dasharray='$outer_dash' stroke-linecap='round' transform='rotate(-90 12 12)'/>
    <circle cx='12' cy='12' r='7' fill='none' stroke='#4ecdc4' stroke-width='3' stroke-dasharray='$middle_dash' stroke-linecap='round' transform='rotate(-90 12 12)'/>
    <circle cx='12' cy='12' r='4' fill='none' stroke='#45b7d1' stroke-width='3' stroke-dasharray='$inner_dash' stroke-linecap='round' transform='rotate(-90 12 12)'/>
  </svg>
  EOF

    # Create tooltip
    tooltip="Duod: Outer=$outer_val/12 Middle=$middle_val/12 Inner=$inner_val/12"

    # Output JSON - Waybar can display images
    cat << EOF
  {"text":"   ","tooltip":"$tooltip","class":"duod-widget"}
  EOF
''
