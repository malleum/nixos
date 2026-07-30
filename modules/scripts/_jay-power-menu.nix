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

    # jay-lock is the themed lock screen, built in modules/programs/jay/_lock.nix
    # because it needs the stylix colours and wallpaper -- things this script,
    # built with a bare `callPackage path {}`, has no access to. It is on the
    # session PATH via home.packages; plain swaylock is the fallback so
    # `nix run .#jay-power-menu` still works standalone.
    case "''${choice# *}" in
      lock)
        if command -v jay-lock >/dev/null; then
          jay-lock
        else
          swaylock -c 000000
        fi
        ;;
      suspend)  systemctl suspend ;;
      logout)   jay quit ;;
      reboot)   systemctl reboot ;;
      shutdown) systemctl poweroff ;;
    esac
  '';
}
