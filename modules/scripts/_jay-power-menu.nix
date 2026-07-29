# rofi power menu. Exists because super+shift+z / super+ctrl+z fired poweroff
# and reboot instantly, with no confirmation step.
{pkgs}:
pkgs.writeShellApplication {
  name = "jay-power-menu";
  runtimeInputs = with pkgs; [swaylock systemd];
  text = ''
    choice=$(printf '%s\n' \
      " lock" \
      " suspend" \
      " logout" \
      " reboot" \
      " shutdown" \
      | rofi -dmenu -i -p power -theme-str 'window {width: 20%;}') || true

    case "''${choice# *}" in
      lock)     swaylock -c 000000 ;;
      suspend)  systemctl suspend ;;
      logout)   jay quit ;;
      reboot)   systemctl reboot ;;
      shutdown) systemctl poweroff ;;
    esac
  '';
}
