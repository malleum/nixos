# Cross-workspace window switcher. rofi's own -show window mode is X11 only;
# the wayland equivalent is wlr-foreign-toplevel, which wlrctl speaks. jay
# hides that protocol from unprivileged clients, so jay.nix carries a
# [[clients]] rule granting wlrctl foreign-toplevel-manager.
{pkgs}:
pkgs.writeShellApplication {
  name = "jay-window-switch";
  runtimeInputs = [pkgs.wlrctl];
  text = ''
    choice=$(wlrctl toplevel list \
      | rofi -dmenu -i -p window -theme-str 'window {width: 60%;}') || true
    [ -z "$choice" ] && exit 0

    # `wlrctl toplevel list` prints "app_id: title". Match on both: app_id
    # alone would always focus the first window of an app, which is useless
    # when you have three browser windows open -- the common case.
    app_id="''${choice%%:*}"
    title="''${choice#*: }"
    wlrctl toplevel focus "app_id:$app_id" "title:$title"
  '';
}
