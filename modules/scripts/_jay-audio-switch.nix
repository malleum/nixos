# Pick an output sink via rofi, make it default, and move every existing
# stream to it (setting the default alone leaves playing audio behind).
#
# The previous version shelled out to `pactl list sinks` once per sink to find
# each description -- O(n^2) subprocesses. pactl speaks JSON, so one call plus
# jq does the whole thing.
#
# rofi comes from the user profile rather than runtimeInputs so the user's own
# theme and config apply.
{pkgs}:
pkgs.writeShellApplication {
  name = "jay-audio-switch";
  runtimeInputs = with pkgs; [pulseaudio jq libnotify];
  text = ''
    # Bluetooth sinks can report a null description; fall back to the name.
    list=$(pactl -f json list sinks 2>/dev/null \
      | jq -r '.[] | "\(.name)\t\(.description // .name)"') || true
    [ -z "$list" ] && exit 0

    choice=$(printf '%s\n' "$list" | cut -f2 | rofi -dmenu -p audio) || true
    [ -z "$choice" ] && exit 0

    # `|| true`: pipefail would abort on a non-matching grep before the check.
    sink=$(printf '%s\n' "$list" | grep -F -m1 "	$choice" | cut -f1) || true
    [ -z "$sink" ] && exit 0

    pactl set-default-sink "$sink"
    pactl -f json list sink-inputs 2>/dev/null \
      | jq -r '.[].index' \
      | while read -r i; do pactl move-sink-input "$i" "$sink"; done

    notify-send -t 1500 "Audio output" "$choice"
  '';
}
